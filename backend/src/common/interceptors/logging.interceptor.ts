import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { FastifyRequest, FastifyReply } from 'fastify';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const ctx = context.switchToHttp();
    const req = ctx.getRequest<FastifyRequest>();
    const res = ctx.getResponse<FastifyReply>();
    const { method, url } = req;
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = Date.now() - now;
          const statusCode = res.statusCode;
          this.logger.log(`${method} ${url} ${statusCode} - ${duration}ms`);
        },
        error: (err) => {
          const duration = Date.now() - now;
          const statusCode = err.status || 500;
          this.logger.warn(`${method} ${url} ${statusCode} - ${duration}ms [Error: ${err.message}]`);
        },
      }),
    );
  }
}
