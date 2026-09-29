import * as bcrypt from 'bcrypt';
import dataSource from '../data-source';
import { User } from '../../users/entities/user.entity';
import { GolfBagClub, ClubType } from '../../golf-bag/entities/golf-bag-club.entity';

async function seed() {
  console.log('--- Starting Development Seed ---');
  await dataSource.initialize();

  const userRepo = dataSource.getRepository(User);
  const clubRepo = dataSource.getRepository(GolfBagClub);

  const testEmail = 'dev@techgolf.com';
  let testUser = await userRepo.findOne({ where: { email: testEmail } });

  if (!testUser) {
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash('Password123!', salt);

    testUser = userRepo.create({
      email: testEmail,
      password_hash,
      full_name: 'Developer Golfer',
      handicap_index: 18.4,
    });
    await userRepo.save(testUser);
    console.log(`Created test user: ${testEmail} (Password: Password123!)`);

    const initialClubs: Partial<GolfBagClub>[] = [
      {
        user_id: testUser.id,
        club_type: ClubType.DRIVER,
        custom_name: 'TaylorMade Stealth 2 Driver',
        average_distance_meters: 225.0,
        total_shots_recorded: 20,
      },
      {
        user_id: testUser.id,
        club_type: ClubType.IRON_7,
        custom_name: 'Titleist T200 7-Iron',
        average_distance_meters: 145.0,
        total_shots_recorded: 35,
      },
      {
        user_id: testUser.id,
        club_type: ClubType.PITCHING_WEDGE,
        custom_name: 'Vokey SM9 PW',
        average_distance_meters: 110.0,
        total_shots_recorded: 28,
      },
      {
        user_id: testUser.id,
        club_type: ClubType.PUTTER,
        custom_name: 'Scotty Cameron Special Select Newport 2',
        average_distance_meters: 0.0,
        total_shots_recorded: 120,
      },
    ];

    for (const clubData of initialClubs) {
      const club = clubRepo.create(clubData);
      await clubRepo.save(club);
    }
    console.log(`Created ${initialClubs.length} sample clubs for dev user.`);
  } else {
    console.log(`Test user ${testEmail} already exists. Skipping.`);
  }

  await dataSource.destroy();
  console.log('--- Development Seed Completed ---');
}

seed().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
