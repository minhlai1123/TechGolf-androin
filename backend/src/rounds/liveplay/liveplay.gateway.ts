import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Logger, Injectable } from '@nestjs/common';
import { Server, WebSocket } from 'ws';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { RoundsService } from '../rounds.service';
import {
  LivePlayEvent,
  LivePlaySocketUser,
  LivePlayJoinPayload,
  LivePlayLeavePayload,
  LivePlayScoreUpdatePayload,
} from './liveplay.types';

@WebSocketGateway({
  path: '/liveplay',
})
@Injectable()
export class LivePlayGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(LivePlayGateway.name);

  // In-memory room manager for active round subscribers
  private readonly roundRooms = new Map<string, Set<WebSocket>>();
  private readonly clientRounds = new Map<WebSocket, Set<string>>();
  private readonly clientUsers = new Map<WebSocket, LivePlaySocketUser>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly roundsService: RoundsService,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  /**
   * Handle new WebSocket connection and authenticate user via JWT
   */
  async handleConnection(client: WebSocket, req?: any) {
    let token: string | null = null;

    if (req && req.url) {
      try {
        const parsedUrl = new URL(req.url, 'http://localhost');
        token = parsedUrl.searchParams.get('token');
      } catch {
        const match = req.url.match(/[?&]token=([^&]+)/);
        if (match) token = match[1];
      }
    }

    if (!token && req && req.headers) {
      const auth = req.headers['authorization'];
      if (auth && typeof auth === 'string' && auth.startsWith('Bearer ')) {
        token = auth.substring(7);
      }
    }

    if (token) {
      await this.authenticateClient(client, token);
    }
  }

  /**
   * Cleans up room subscriptions and client mapping upon disconnect
   */
  handleDisconnect(client: WebSocket) {
    const user = this.clientUsers.get(client);
    const rooms = this.clientRounds.get(client);

    if (rooms) {
      for (const roundId of rooms) {
        const room = this.roundRooms.get(roundId);
        if (room) {
          room.delete(client);
          if (room.size === 0) {
            this.roundRooms.delete(roundId);
          } else if (user) {
            this.broadcastToRound(roundId, LivePlayEvent.PLAYER_LEFT, {
              roundId,
              userId: user.userId,
              playerName: user.fullName || user.email,
            });
          }
        }
      }
    }

    this.clientRounds.delete(client);
    this.clientUsers.delete(client);
    this.logger.log(`LivePlay client disconnected. User: ${user?.userId || 'anonymous'}`);
  }

  /**
   * Internal helper to verify JWT and attach authenticated user to socket
   */
  async authenticateClient(client: WebSocket, token: string): Promise<LivePlaySocketUser | null> {
    try {
      const payload = await this.jwtService.verifyAsync(token);
      if (!payload || !payload.sub) {
        return null;
      }

      const user = await this.userRepo.findOne({ where: { id: payload.sub } });
      if (!user) {
        return null;
      }

      const socketUser: LivePlaySocketUser = {
        userId: user.id,
        email: user.email,
        fullName: user.full_name,
      };

      this.clientUsers.set(client, socketUser);
      return socketUser;
    } catch (err) {
      this.logger.warn(`WebSocket authentication failed: ${err.message}`);
      return null;
    }
  }

  /**
   * Player joins a LivePlay round room
   */
  @SubscribeMessage(LivePlayEvent.JOIN)
  async handleJoin(
    @ConnectedSocket() client: WebSocket,
    @MessageBody() data: LivePlayJoinPayload & { token?: string },
  ) {
    let user = this.clientUsers.get(client);

    // If client provided token in payload, attempt authentication
    if (!user && data && data.token) {
      user = await this.authenticateClient(client, data.token);
    }

    if (!user) {
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: 'Unauthorized: Valid JWT authentication required to join LivePlay.',
      });
      return;
    }

    if (!data || !data.roundId) {
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: 'BadRequest: roundId is required to join LivePlay.',
      });
      return;
    }

    try {
      // Validate round exists and user belongs to the round
      await this.roundsService.validateRoundAccess(data.roundId, user.userId);

      // Add client to room
      if (!this.roundRooms.has(data.roundId)) {
        this.roundRooms.set(data.roundId, new Set<WebSocket>());
      }
      this.roundRooms.get(data.roundId)!.add(client);

      if (!this.clientRounds.has(client)) {
        this.clientRounds.set(client, new Set<string>());
      }
      this.clientRounds.get(client)!.add(data.roundId);

      // Retrieve full initial LivePlay state (database = source of truth)
      const state = await this.roundsService.getLivePlayState(data.roundId, user.userId);

      // Respond directly to the joining client
      this.sendToClient(client, LivePlayEvent.JOINED, {
        roundId: data.roundId,
        userId: user.userId,
        state,
        message: `Successfully joined LivePlay for round ${data.roundId}`,
      });

      // Broadcast to other players in the round
      this.broadcastToRound(
        data.roundId,
        LivePlayEvent.PLAYER_JOINED,
        {
          roundId: data.roundId,
          userId: user.userId,
          playerName: user.fullName || user.email,
        },
        client, // exclude self
      );

      this.logger.log(`User ${user.userId} joined LivePlay round ${data.roundId}`);
    } catch (err) {
      this.logger.error(`Error joining LivePlay round ${data.roundId}: ${err.message}`);
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: err.message || 'Failed to join LivePlay round',
      });
    }
  }

  /**
   * Player leaves a LivePlay round room
   */
  @SubscribeMessage(LivePlayEvent.LEAVE)
  async handleLeave(
    @ConnectedSocket() client: WebSocket,
    @MessageBody() data: LivePlayLeavePayload,
  ) {
    const user = this.clientUsers.get(client);
    if (!data || !data.roundId) return;

    const room = this.roundRooms.get(data.roundId);
    if (room) {
      room.delete(client);
      if (room.size === 0) {
        this.roundRooms.delete(data.roundId);
      }
    }

    const clientRooms = this.clientRounds.get(client);
    if (clientRooms) {
      clientRooms.delete(data.roundId);
    }

    this.sendToClient(client, LivePlayEvent.LEFT, {
      roundId: data.roundId,
      message: 'Successfully left LivePlay room',
    });

    if (user) {
      this.broadcastToRound(data.roundId, LivePlayEvent.PLAYER_LEFT, {
        roundId: data.roundId,
        userId: user.userId,
        playerName: user.fullName || user.email,
      });
    }
  }

  /**
   * Player submits or updates score in realtime
   */
  @SubscribeMessage(LivePlayEvent.SCORE_UPDATE)
  async handleScoreUpdate(
    @ConnectedSocket() client: WebSocket,
    @MessageBody() data: LivePlayScoreUpdatePayload,
  ) {
    const user = this.clientUsers.get(client);

    if (!user) {
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: 'Unauthorized: Authentication required to submit scores.',
      });
      return;
    }

    if (!data || !data.roundId || !data.holeId || data.grossScore === undefined || data.grossScore <= 0) {
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: 'Invalid score payload: roundId, holeId, and positive grossScore are required.',
      });
      return;
    }

    try {
      // 1. Save score to database and recalculate leaderboard
      const result = await this.roundsService.saveLivePlayScore(data.roundId, user.userId, {
        holeId: data.holeId,
        playerId: data.playerId,
        grossScore: data.grossScore,
        putts: data.putts,
        penalties: data.penalties,
        fairwayHit: data.fairwayHit,
        gir: data.gir,
      });

      // 2. Broadcast score:updated to all connected players in room
      this.broadcastToRound(data.roundId, LivePlayEvent.SCORE_UPDATED, {
        roundId: data.roundId,
        score: result.score,
        updatedByUserId: user.userId,
      });

      // 3. Broadcast leaderboard:updated with recalculated real-time standings
      this.broadcastToRound(data.roundId, LivePlayEvent.LEADERBOARD_UPDATED, {
        roundId: data.roundId,
        leaderboard: result.leaderboard,
        playerSummaries: result.playerSummaries,
        currentHole: result.currentHole,
      });

      this.logger.log(`LivePlay score updated for round ${data.roundId}, hole ${data.holeId}`);
    } catch (err) {
      this.logger.error(`Error saving LivePlay score: ${err.message}`);
      // Only broadcast on success! On error, notify only the calling client.
      this.sendToClient(client, LivePlayEvent.ERROR, {
        message: err.message || 'Failed to save score in LivePlay.',
      });
    }
  }

  /**
   * Helper to send JSON event to a single client socket
   */
  sendToClient(client: WebSocket, event: string, data: any) {
    if (client && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({ event, data }));
    }
  }

  /**
   * Helper to broadcast JSON event to all connected sockets in a round room
   */
  broadcastToRound(roundId: string, event: string, data: any, excludeClient?: WebSocket) {
    const room = this.roundRooms.get(roundId);
    if (!room) return;

    const message = JSON.stringify({ event, data });
    for (const client of room) {
      if (client !== excludeClient && client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    }
  }

  /**
   * Check room size for testing and monitoring
   */
  getRoomSize(roundId: string): number {
    return this.roundRooms.get(roundId)?.size || 0;
  }
}
