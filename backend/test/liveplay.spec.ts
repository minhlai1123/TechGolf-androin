import { LivePlayGateway } from '../src/rounds/liveplay/liveplay.gateway';
import { LivePlayEvent } from '../src/rounds/liveplay/liveplay.types';
import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { WebSocket } from 'ws';

describe('LivePlayGateway & Realtime Synchronization', () => {
  let gateway: LivePlayGateway;
  let mockJwtService: any;
  let mockRoundsService: any;
  let mockUserRepo: any;

  const roundId = 'round-uuid-1111';
  const playerAId = 'user-uuid-aaaa';
  const playerBId = 'user-uuid-bbbb';
  const unauthorizedUserId = 'user-uuid-xxxx';

  // Helper to create a fake WebSocket client
  function createMockSocket(id: string = 'socket-1'): any {
    const sentMessages: any[] = [];
    return {
      id,
      readyState: WebSocket.OPEN,
      send: jest.fn((msg: string) => {
        sentMessages.push(JSON.parse(msg));
      }),
      close: jest.fn(),
      sentMessages,
      getLastMessage: () => sentMessages[sentMessages.length - 1],
    };
  }

  beforeEach(() => {
    mockJwtService = {
      verifyAsync: jest.fn(),
    };

    mockUserRepo = {
      findOne: jest.fn(),
    };

    mockRoundsService = {
      validateRoundAccess: jest.fn(),
      getLivePlayState: jest.fn(),
      saveLivePlayScore: jest.fn(),
    };

    gateway = new LivePlayGateway(
      mockJwtService,
      mockRoundsService,
      mockUserRepo,
    );
  });

  describe('Connection & JWT Authentication', () => {
    it('authenticates socket when valid token is in query parameters', async () => {
      const socket = createMockSocket();
      const token = 'valid-jwt-token';
      mockJwtService.verifyAsync.mockResolvedValue({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValue({
        id: playerAId,
        email: 'tiger@golf.com',
        full_name: 'Tiger Woods',
      });

      const req = { url: `/liveplay?token=${token}` };
      await gateway.handleConnection(socket, req);

      expect(mockJwtService.verifyAsync).toHaveBeenCalledWith(token);
      expect(mockUserRepo.findOne).toHaveBeenCalledWith({ where: { id: playerAId } });
    });

    it('authenticates socket when valid token is in Authorization header', async () => {
      const socket = createMockSocket();
      const token = 'bearer-jwt-token';
      mockJwtService.verifyAsync.mockResolvedValue({ sub: playerBId });
      mockUserRepo.findOne.mockResolvedValue({
        id: playerBId,
        email: 'rory@golf.com',
        full_name: 'Rory McIlroy',
      });

      const req = { headers: { authorization: `Bearer ${token}` } };
      await gateway.handleConnection(socket, req);

      expect(mockJwtService.verifyAsync).toHaveBeenCalledWith(token);
    });

    it('rejects connection if token is invalid or verification fails', async () => {
      const socket = createMockSocket();
      mockJwtService.verifyAsync.mockRejectedValue(new Error('jwt expired'));

      const req = { url: '/liveplay?token=expired-token' };
      await gateway.handleConnection(socket, req);

      // Attempting to join without valid auth will return Unauthorized error
      await gateway.handleJoin(socket, { roundId });
      expect(socket.getLastMessage().event).toBe(LivePlayEvent.ERROR);
      expect(socket.getLastMessage().data.message).toContain('Unauthorized');
    });
  });

  describe('Join & Leave Round Room', () => {
    beforeEach(async () => {
      // Setup authenticated socket for Player A
      mockJwtService.verifyAsync.mockResolvedValue({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValue({
        id: playerAId,
        email: 'tiger@golf.com',
        full_name: 'Tiger Woods',
      });
    });

    it('allows round player to join and returns initial live state', async () => {
      const socketA = createMockSocket('socket-a');
      await gateway.authenticateClient(socketA, 'valid-token');

      const mockState = {
        round: { id: roundId, currentHole: 1 },
        course: { name: 'Pebble Beach' },
        players: [{ id: 'p1', playerName: 'Tiger Woods' }],
        leaderboard: { strokePlay: [] },
      };

      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue(mockState);

      await gateway.handleJoin(socketA, { roundId });

      expect(mockRoundsService.validateRoundAccess).toHaveBeenCalledWith(roundId, playerAId);
      expect(socketA.getLastMessage().event).toBe(LivePlayEvent.JOINED);
      expect(socketA.getLastMessage().data.state).toEqual(mockState);
      expect(gateway.getRoomSize(roundId)).toBe(1);
    });

    it('rejects unauthorized user who is not a player in the round', async () => {
      const socketUnauthorized = createMockSocket('socket-x');
      mockJwtService.verifyAsync.mockResolvedValue({ sub: unauthorizedUserId });
      mockUserRepo.findOne.mockResolvedValue({ id: unauthorizedUserId });
      await gateway.authenticateClient(socketUnauthorized, 'token-x');

      mockRoundsService.validateRoundAccess.mockRejectedValue(
        new ForbiddenException('You do not have access to this round'),
      );

      await gateway.handleJoin(socketUnauthorized, { roundId });

      expect(socketUnauthorized.getLastMessage().event).toBe(LivePlayEvent.ERROR);
      expect(socketUnauthorized.getLastMessage().data.message).toContain('You do not have access');
      expect(gateway.getRoomSize(roundId)).toBe(0);
    });

    it('broadcasts player:joined to other players when a new player joins', async () => {
      // Player A is already in the room
      const socketA = createMockSocket('socket-a');
      await gateway.authenticateClient(socketA, 'token-a');
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({});
      await gateway.handleJoin(socketA, { roundId });

      // Player B joins the room
      const socketB = createMockSocket('socket-b');
      mockJwtService.verifyAsync.mockResolvedValue({ sub: playerBId });
      mockUserRepo.findOne.mockResolvedValue({
        id: playerBId,
        email: 'rory@golf.com',
        full_name: 'Rory McIlroy',
      });
      await gateway.authenticateClient(socketB, 'token-b');
      await gateway.handleJoin(socketB, { roundId });

      // Socket A should have received PLAYER_JOINED event about Rory
      const playerJoinedMsg = socketA.sentMessages.find(
        (m: any) => m.event === LivePlayEvent.PLAYER_JOINED,
      );
      expect(playerJoinedMsg).toBeDefined();
      expect(playerJoinedMsg.data.playerName).toBe('Rory McIlroy');
      expect(gateway.getRoomSize(roundId)).toBe(2);
    });

    it('handles leave and disconnect cleanly without memory leaks', async () => {
      const socketA = createMockSocket('socket-a');
      await gateway.authenticateClient(socketA, 'token-a');
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({});
      await gateway.handleJoin(socketA, { roundId });

      expect(gateway.getRoomSize(roundId)).toBe(1);

      // Player A leaves
      await gateway.handleLeave(socketA, { roundId });
      expect(socketA.getLastMessage().event).toBe(LivePlayEvent.LEFT);
      expect(gateway.getRoomSize(roundId)).toBe(0);
    });
  });

  describe('Multiplayer Realtime Score Update & Leaderboard Sync', () => {
    it('Player A updates score -> DB saves -> Player A and Player B receive score:updated and leaderboard:updated', async () => {
      // 1. Setup Player A in room
      const socketA = createMockSocket('socket-a');
      mockJwtService.verifyAsync.mockResolvedValueOnce({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValueOnce({ id: playerAId, full_name: 'Tiger' });
      await gateway.authenticateClient(socketA, 'token-a');
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({});
      await gateway.handleJoin(socketA, { roundId });

      // 2. Setup Player B in room
      const socketB = createMockSocket('socket-b');
      mockJwtService.verifyAsync.mockResolvedValueOnce({ sub: playerBId });
      mockUserRepo.findOne.mockResolvedValueOnce({ id: playerBId, full_name: 'Rory' });
      await gateway.authenticateClient(socketB, 'token-b');
      await gateway.handleJoin(socketB, { roundId });

      // 3. Player A updates score for Hole 1
      const updatePayload = {
        roundId,
        holeId: 'hole-1',
        grossScore: 4,
        putts: 2,
        penalties: 0,
      };

      const mockSaveResult = {
        score: { id: 'score-1', holeId: 'hole-1', grossScore: 4 },
        leaderboard: {
          strokePlay: [
            { playerId: 'p1', playerName: 'Tiger', grossScore: 4, rank: 1 },
          ],
        },
        playerSummaries: [{ playerId: 'p1', grossScore: 4, thru: '1' }],
        currentHole: 2,
      };

      mockRoundsService.saveLivePlayScore.mockResolvedValue(mockSaveResult);

      await gateway.handleScoreUpdate(socketA, updatePayload);

      // Verify DB was called to save score
      expect(mockRoundsService.saveLivePlayScore).toHaveBeenCalledWith(
        roundId,
        playerAId,
        expect.objectContaining({
          holeId: 'hole-1',
          grossScore: 4,
          putts: 2,
          penalties: 0,
        }),
      );

      // Verify Player B received score:updated
      const scoreMsgB = socketB.sentMessages.find((m: any) => m.event === LivePlayEvent.SCORE_UPDATED);
      expect(scoreMsgB).toBeDefined();
      expect(scoreMsgB.data.score.grossScore).toBe(4);

      // Verify Player B received leaderboard:updated with recalculated standings
      const leaderboardMsgB = socketB.sentMessages.find(
        (m: any) => m.event === LivePlayEvent.LEADERBOARD_UPDATED,
      );
      expect(leaderboardMsgB).toBeDefined();
      expect(leaderboardMsgB.data.leaderboard.strokePlay[0].playerName).toBe('Tiger');
      expect(leaderboardMsgB.data.currentHole).toBe(2);

      // Verify Player A also received leaderboard:updated
      const leaderboardMsgA = socketA.sentMessages.find(
        (m: any) => m.event === LivePlayEvent.LEADERBOARD_UPDATED,
      );
      expect(leaderboardMsgA).toBeDefined();
    });

    it('rejects invalid score (grossScore <= 0) and does NOT broadcast to room', async () => {
      const socketA = createMockSocket('socket-a');
      mockJwtService.verifyAsync.mockResolvedValueOnce({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValueOnce({ id: playerAId });
      await gateway.authenticateClient(socketA, 'token-a');
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({});
      await gateway.handleJoin(socketA, { roundId });

      const invalidPayload = {
        roundId,
        holeId: 'hole-1',
        grossScore: 0, // Invalid!
      };

      await gateway.handleScoreUpdate(socketA, invalidPayload);

      expect(mockRoundsService.saveLivePlayScore).not.toHaveBeenCalled();
      expect(socketA.getLastMessage().event).toBe(LivePlayEvent.ERROR);
      expect(socketA.getLastMessage().data.message).toContain('positive grossScore');
    });

    it('handles database save failure gracefully without broadcasting', async () => {
      const socketA = createMockSocket('socket-a');
      mockJwtService.verifyAsync.mockResolvedValueOnce({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValueOnce({ id: playerAId });
      await gateway.authenticateClient(socketA, 'token-a');
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({});
      await gateway.handleJoin(socketA, { roundId });

      mockRoundsService.saveLivePlayScore.mockRejectedValue(
        new BadRequestException('Putts cannot exceed gross score'),
      );

      await gateway.handleScoreUpdate(socketA, {
        roundId,
        holeId: 'hole-1',
        grossScore: 3,
        putts: 5,
      });

      expect(socketA.getLastMessage().event).toBe(LivePlayEvent.ERROR);
      expect(socketA.getLastMessage().data.message).toContain('Putts cannot exceed');

      // No SCORE_UPDATED event was sent
      const scoreMsg = socketA.sentMessages.find((m: any) => m.event === LivePlayEvent.SCORE_UPDATED);
      expect(scoreMsg).toBeUndefined();
    });
  });

  describe('Reconnection & Initial Sync', () => {
    it('authenticates via token in join payload on reconnect and sends fresh state', async () => {
      const socket = createMockSocket();
      mockJwtService.verifyAsync.mockResolvedValue({ sub: playerAId });
      mockUserRepo.findOne.mockResolvedValue({ id: playerAId, full_name: 'Tiger' });
      mockRoundsService.validateRoundAccess.mockResolvedValue({ id: roundId });
      mockRoundsService.getLivePlayState.mockResolvedValue({
        round: { id: roundId, currentHole: 5 },
        leaderboard: {},
      });

      // Token passed directly in join payload (reconnect scenario)
      await gateway.handleJoin(socket, { roundId, token: 'reconnect-jwt-token' });

      expect(socket.getLastMessage().event).toBe(LivePlayEvent.JOINED);
      expect(socket.getLastMessage().data.state.round.currentHole).toBe(5);
    });
  });
});
