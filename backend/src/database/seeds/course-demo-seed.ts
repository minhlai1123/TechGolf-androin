/**
 * ============================================================================
 * NOTICE: THIS FILE CONTAINS DEMO / DEVELOPMENT DATA ONLY.
 * It is intended exclusively for local development, API testing, and UI verification.
 * No proprietary golf course survey data is included.
 * ============================================================================
 */

import * as bcrypt from 'bcrypt';
import dataSource from '../data-source';
import { User, UserRole } from '../../users/entities/user.entity';
import { Course, CourseStatus } from '../../courses/entities/course.entity';
import { CourseTee } from '../../courses/entities/course-tee.entity';
import { Hole } from '../../courses/entities/hole.entity';
import { HoleTee } from '../../courses/entities/hole-tee.entity';
import { HolePolygon, PolygonType } from '../../courses/entities/hole-polygon.entity';
import { GeoJsonHelper } from '../../common/gis/geojson.helper';

async function seed() {
  console.log('=== Starting Phase 2 Demo Course Seed ===');
  await dataSource.initialize();

  const userRepo = dataSource.getRepository(User);
  const courseRepo = dataSource.getRepository(Course);
  const courseTeeRepo = dataSource.getRepository(CourseTee);
  const holeRepo = dataSource.getRepository(Hole);
  const holeTeeRepo = dataSource.getRepository(HoleTee);
  const polygonRepo = dataSource.getRepository(HolePolygon);

  // 1. Create or ensure Admin user exists
  const adminEmail = 'admin@techgolf.com';
  let adminUser = await userRepo.findOne({ where: { email: adminEmail } });
  if (!adminUser) {
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash('AdminPassword123!', salt);
    adminUser = userRepo.create({
      email: adminEmail,
      password_hash,
      full_name: 'Lead Course Admin',
      role: UserRole.ADMIN,
      handicap_index: 5.4,
    });
    await userRepo.save(adminUser);
    console.log(`Created Admin user: ${adminEmail} (Password: AdminPassword123!)`);
  } else {
    adminUser.role = UserRole.ADMIN;
    await userRepo.save(adminUser);
    console.log(`Admin user ${adminEmail} already exists, verified role ADMIN.`);
  }

  // 2. Create Demo Golf Course
  const demoCourseName = 'Pine Valley Championship Golf Club (DEMO / DEVELOPMENT DATA ONLY)';
  let course = await courseRepo.findOne({ where: { name: demoCourseName } });

  if (!course) {
    course = courseRepo.create({
      name: demoCourseName,
      address: '100 Fairway Boulevard, Golf Valley',
      city: 'Hanoi',
      country: 'Vietnam',
      latitude: 21.0285,
      longitude: 105.8542,
      location: GeoJsonHelper.pointToWkt(105.8542, 21.0285),
      timezone: 'Asia/Ho_Chi_Minh',
      total_holes: 18,
      status: CourseStatus.ACTIVE,
      description: 'Championship 18-hole golf facility used for development and testing of Hole19 rangefinder clone.',
    });
    await courseRepo.save(course);
    console.log(`Created Course: ${course.name}`);

    // 3. Create Course Tees (Black, Blue, White, Red)
    const teesData = [
      { name: 'Black', color: '#0F172A', rating: 75.2, slope_rating: 142, total_yardage: 7250 },
      { name: 'Blue', color: '#2563EB', rating: 73.1, slope_rating: 135, total_yardage: 6820 },
      { name: 'White', color: '#F8FAFC', rating: 71.0, slope_rating: 128, total_yardage: 6410 },
      { name: 'Red', color: '#EF4444', rating: 69.5, slope_rating: 120, total_yardage: 5890 },
    ];

    const createdTees: CourseTee[] = [];
    for (const t of teesData) {
      const tee = courseTeeRepo.create({
        course_id: course.id,
        ...t,
      });
      createdTees.push(await courseTeeRepo.save(tee));
    }
    console.log(`Created ${createdTees.length} Course Tees (Black, Blue, White, Red).`);

    // 4. Create 9 Demo Holes with full mapping data
    const holesConfig = [
      { num: 1, par: 4, hcp: 7, baseLat: 21.0285, baseLng: 105.8542 },
      { num: 2, par: 3, hcp: 17, baseLat: 21.0310, baseLng: 105.8560 },
      { num: 3, par: 5, hcp: 1, baseLat: 21.0335, baseLng: 105.8575 },
      { num: 4, par: 4, hcp: 9, baseLat: 21.0350, baseLng: 105.8550 },
      { num: 5, par: 4, hcp: 5, baseLat: 21.0330, baseLng: 105.8525 },
      { num: 6, par: 3, hcp: 15, baseLat: 21.0315, baseLng: 105.8510 },
      { num: 7, par: 5, hcp: 3, baseLat: 21.0290, baseLng: 105.8490 },
      { num: 8, par: 4, hcp: 11, baseLat: 21.0270, baseLng: 105.8515 },
      { num: 9, par: 4, hcp: 13, baseLat: 21.0275, baseLng: 105.8535 },
    ];

    for (const hConfig of holesConfig) {
      const teeLng = hConfig.baseLng;
      const teeLat = hConfig.baseLat;
      const greenCenterLng = teeLng + 0.0030;
      const greenCenterLat = teeLat + 0.0025;
      const greenFrontLng = greenCenterLng - 0.00015;
      const greenFrontLat = greenCenterLat - 0.00015;
      const greenBackLng = greenCenterLng + 0.00015;
      const greenBackLat = greenCenterLat + 0.00015;

      const hole = holeRepo.create({
        course_id: course.id,
        hole_number: hConfig.num,
        par: hConfig.par,
        handicap_index: hConfig.hcp,
        green_center: GeoJsonHelper.pointToWkt(greenCenterLng, greenCenterLat),
        green_front: GeoJsonHelper.pointToWkt(greenFrontLng, greenFrontLat),
        green_back: GeoJsonHelper.pointToWkt(greenBackLng, greenBackLat),
      });
      const savedHole = await holeRepo.save(hole);

      // Add Hole Tees
      for (let i = 0; i < createdTees.length; i++) {
        const offset = i * 0.0001;
        const ht = holeTeeRepo.create({
          hole_id: savedHole.id,
          course_tee_id: createdTees[i].id,
          tee_position: GeoJsonHelper.pointToWkt(teeLng - offset, teeLat - offset),
          distance_meters: (hConfig.par === 3 ? 160 : hConfig.par === 4 ? 380 : 510) - i * 15,
        });
        await holeTeeRepo.save(ht);
      }

      // Add Vector Polygons (Fairway, Green, Bunker, Water Hazard, Rough, Tee)
      // Green Polygon
      const greenPolyCoords = [
        [
          [greenCenterLng - 0.00025, greenCenterLat - 0.00025],
          [greenCenterLng + 0.00025, greenCenterLat - 0.00025],
          [greenCenterLng + 0.00025, greenCenterLat + 0.00025],
          [greenCenterLng - 0.00025, greenCenterLat + 0.00025],
          [greenCenterLng - 0.00025, greenCenterLat - 0.00025],
        ],
      ];
      await polygonRepo.save(
        polygonRepo.create({
          hole_id: savedHole.id,
          polygon_type: PolygonType.GREEN,
          geometry: GeoJsonHelper.polygonToWkt(greenPolyCoords),
        }),
      );

      // Fairway Polygon
      const fairwayCoords = [
        [
          [teeLng + 0.0005, teeLat + 0.0004],
          [greenCenterLng - 0.0004, greenCenterLat - 0.0003],
          [greenCenterLng - 0.0002, greenCenterLat - 0.0005],
          [teeLng + 0.0007, teeLat + 0.0002],
          [teeLng + 0.0005, teeLat + 0.0004],
        ],
      ];
      await polygonRepo.save(
        polygonRepo.create({
          hole_id: savedHole.id,
          polygon_type: PolygonType.FAIRWAY,
          geometry: GeoJsonHelper.polygonToWkt(fairwayCoords),
        }),
      );

      // Bunker Polygon (Greenside Sand Trap)
      const bunkerCoords = [
        [
          [greenCenterLng + 0.0003, greenCenterLat + 0.0001],
          [greenCenterLng + 0.00045, greenCenterLat + 0.0001],
          [greenCenterLng + 0.00045, greenCenterLat + 0.00025],
          [greenCenterLng + 0.0003, greenCenterLat + 0.00025],
          [greenCenterLng + 0.0003, greenCenterLat + 0.0001],
        ],
      ];
      await polygonRepo.save(
        polygonRepo.create({
          hole_id: savedHole.id,
          polygon_type: PolygonType.BUNKER,
          geometry: GeoJsonHelper.polygonToWkt(bunkerCoords),
          metadata: { trap_type: 'greenside_right' },
        }),
      );

      // Water Hazard Polygon
      const waterCoords = [
        [
          [teeLng + 0.0015, teeLat + 0.0008],
          [teeLng + 0.0022, teeLat + 0.0008],
          [teeLng + 0.0022, teeLat + 0.0013],
          [teeLng + 0.0015, teeLat + 0.0013],
          [teeLng + 0.0015, teeLat + 0.0008],
        ],
      ];
      await polygonRepo.save(
        polygonRepo.create({
          hole_id: savedHole.id,
          polygon_type: PolygonType.WATER_HAZARD,
          geometry: GeoJsonHelper.polygonToWkt(waterCoords),
          metadata: { hazard_type: 'lateral_pond' },
        }),
      );
    }

    console.log(`Created 9 demo holes with complete Tees, Green points and Vector Polygons.`);
  } else {
    console.log(`Demo course '${demoCourseName}' already exists.`);
  }

  await dataSource.destroy();
  console.log('=== Phase 2 Demo Course Seed Completed Successfully ===');
}

seed().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
