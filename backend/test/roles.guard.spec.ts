import { Reflector } from '@nestjs/core';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { RolesGuard } from '../src/common/guards/roles.guard';
import { UserRole } from '../src/users/entities/user.entity';

describe('RolesGuard Tests', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    guard = new RolesGuard(reflector);
  });

  function createMockContext(user: any): ExecutionContext {
    return {
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
    } as any;
  }

  it('should allow access if no roles are required on route', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const context = createMockContext({ userId: 'u1', role: UserRole.USER });

    expect(guard.canActivate(context)).toBe(true);
  });

  it('should ALLOW access when user has ADMIN role on @Roles(ADMIN) route', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext({ userId: 'u1', role: UserRole.ADMIN });

    expect(guard.canActivate(context)).toBe(true);
  });

  it('should FORBID access when user has regular USER role on @Roles(ADMIN) route', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext({ userId: 'u1', role: UserRole.USER });

    expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
  });

  it('should FORBID access when request has no authenticated user', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext(null);

    expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
  });
});
