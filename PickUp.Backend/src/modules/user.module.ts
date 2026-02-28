import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../core/entities/user.entity';
import { UserService } from '../services/user.service';
import { UserController } from '../controller/user.controller';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    JwtModule.register({
      secret: '8f92b3c4e5a6d7f8g9h0j1k2l3m4n5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2', // Usa una variabile d'ambiente in produzione!
      signOptions: { expiresIn: '7d' },    // Il token durerà 7 giorni
    }),
  ],// Importante per usare Repository<User>
  providers: [UserService],
  controllers: [UserController],
})
export class UserModule {}