import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../core/entities/user.entity';
import { UserService } from '../services/user.service';
import { UserController } from '../controller/user.controller';

@Module({
  imports: [TypeOrmModule.forFeature([User])], // Importante per usare Repository<User>
  providers: [UserService],
  controllers: [UserController],
})
export class UserModule {}