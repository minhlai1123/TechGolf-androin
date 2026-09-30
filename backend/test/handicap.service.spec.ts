import { HandicapService } from '../src/handicap/handicap.service';

describe('HandicapService', () => {
  let service: HandicapService;
  let historyRepo: any;
  let diffRepo: any;
  let userRepo: any;
  let roundRepo: any;
  let playerRepo: any;
  let scoreRepo: any;
  let teeRepo: any;

  beforeEach(() => {
    historyRepo = {
      findOne: jest.fn(),
      find: jest.fn(),
      create: jest.fn((dto) => dto),
      save: jest.fn((entity) => Promise.resolve(entity)),
    };
    diffRepo = {
      count: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn((dto) => dto),
      save: jest.fn((entity) => Promise.resolve(entity)),
    };
    userRepo = {
      findOne: jest.fn(),
      save: jest.fn((user) => Promise.resolve(user)),
    };
    roundRepo = {
      find: jest.fn(),
    };
    playerRepo = {
      find: jest.fn(),
    };
    scoreRepo = {
      find: jest.fn(),
    };
    teeRepo = {
      findOne: jest.fn(),
    };

    service = new HandicapService(
      historyRepo,
      diffRepo,
      userRepo,
      roundRepo,
      playerRepo,
      scoreRepo,
      teeRepo,
    );
  });

  describe('getCurrentHandicap', () => {
    it('returns unestablished status when user has less than 3 differentials', async () => {
      userRepo.findOne.mockResolvedValue({ id: 'user-1', handicap_index: 54.0 });
      historyRepo.findOne.mockResolvedValue(null);
      diffRepo.count.mockResolvedValue(2);

      const result = await service.getCurrentHandicap('user-1');
      expect(result.isEstablished).toBe(false);
      expect(result.roundsCount).toBe(2);
      expect(result.message).toContain('Needs at least 3 completed 18-hole rounds');
    });

    it('returns established status with handicap index when user has >= 3 differentials', async () => {
      userRepo.findOne.mockResolvedValue({ id: 'user-1', handicap_index: 14.2 });
      historyRepo.findOne.mockResolvedValue({
        id: 'hist-1',
        resulting_handicap_index: 14.2,
        calculated_at: new Date('2026-09-20T10:00:00Z'),
        status: 'ESTABLISHED',
      });
      diffRepo.count.mockResolvedValue(5);

      const result = await service.getCurrentHandicap('user-1');
      expect(result.isEstablished).toBe(true);
      expect(result.handicapIndex).toBe(14.2);
      expect(result.roundsCount).toBe(5);
      expect(result.status).toBe('ESTABLISHED');
    });
  });

  describe('getHandicapHistory', () => {
    it('fetches chronological handicap history', async () => {
      const mockHistory = [
        { id: 'h1', resulting_handicap_index: 14.2 },
        { id: 'h2', resulting_handicap_index: 15.5 },
      ];
      historyRepo.find.mockResolvedValue(mockHistory);

      const res = await service.getHandicapHistory('user-1');
      expect(res).toEqual(mockHistory);
      expect(historyRepo.find).toHaveBeenCalledWith({
        where: { user_id: 'user-1' },
        order: { calculated_at: 'DESC' },
      });
    });
  });

  describe('getScoreDifferentials', () => {
    it('fetches score differentials with relations', async () => {
      const mockDiffs = [
        { id: 'd1', score_differential: 13.5 },
        { id: 'd2', score_differential: 16.2 },
      ];
      diffRepo.find.mockResolvedValue(mockDiffs);

      const res = await service.getScoreDifferentials('user-1');
      expect(res).toEqual(mockDiffs);
      expect(diffRepo.find).toHaveBeenCalledWith({
        where: { user_id: 'user-1' },
        relations: ['course', 'courseTee'],
        order: { played_at: 'DESC' },
      });
    });
  });
});
