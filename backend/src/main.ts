import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: false }),
  );

  const configService = app.get(ConfigService);
  const port = configService.get<number>('port') || 3000;
  const host = configService.get<string>('host') || '0.0.0.0';

  // 1. Global Prefix: /api/v1
  app.setGlobalPrefix('api/v1');

  // 2. Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // 3. Global Exception Filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // 4. Global Logging Interceptor
  app.useGlobalInterceptors(new LoggingInterceptor());

  // 5. Swagger / OpenAPI Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('TechGolf Core API')
    .setDescription(
      'TechGolf Rangefinder, Scorecard, Shot Tracking & Golf Community Platform API - Phase 1 Foundation',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT Access Token',
        in: 'header',
      },
      'JWT-auth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  // 6. Start Fastify server
  await app.listen(port, host);
  logger.log(`====================================================`);
  logger.log(`TechGolf Backend API running on: http://${host}:${port}/api/v1`);
  logger.log(`Swagger OpenAPI Documentation:   http://${host}:${port}/api/docs`);
  logger.log(`Health Check Endpoint:           http://${host}:${port}/api/v1/health`);
  logger.log(`====================================================`);
}

bootstrap().catch((err) => {
  console.error('Fatal error during bootstrap:', err);
  process.exit(1);
});
