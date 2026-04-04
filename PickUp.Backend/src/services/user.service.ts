import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../core/models/user';
import { Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import 'multer';

@Injectable()
export class UserService {
    constructor(
        @InjectRepository(User)
        private readonly userRepository: Repository<User>,
        private readonly jwtService: JwtService
    ) {}

  async register(dto: User) {
    // 1. Genera un "salt" e crea l'hash della password
    // Il numero 10 è il "cost factor" (bilanciamento tra sicurezza e velocità)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(dto.password, salt);

    // 2. Sostituisci la password in chiaro con quella hashata
    const newUser = this.userRepository.create({
      ...dto,
      password: hashedPassword,
    });
    
    return await this.userRepository.save(newUser);
  }

  async login(emailUsername: string, password: string) {
    let user = await this.getUserByEmailWithPassword(emailUsername);

    if (!user) {
      user = await this.getUserByUsernameWithPassword(emailUsername);

      if (!user) {
        return null;
      }
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (isMatch) {
      const payload = { sub: user.id, username: user.username };
      return {
        access_token: await this.jwtService.signAsync(payload),
      };
    }
    return null;
  }

  async getUserByEmailWithPassword(email: string) {
    return await this.userRepository.findOne({
      where: { email },
      select: ['id', 'email', 'password', 'username'] // Chiedi esplicitamente la password
    });
  }

  async getUserByUsernameWithPassword(username: string) {
    return await this.userRepository.findOne({
      where: { username },
      select: ['id', 'email', 'password', 'username'] // Chiedi esplicitamente la password
    });
  }

  async getUserByEmail(email: string) {
    const user = await this.userRepository.findOne({ where: { email } });

    if (!user) {
      return null;
    }

    return user;
  }

  async getUserByEmailPrivate(email: string) {
    const user = await this.userRepository.findOne({ where: { email } });

    if (!user) {
      return null;
    }

    return user;
  }

  async getUserByUsername(username: string) {
    const user = await this.userRepository.findOne({ where: { username } });

    if (!user) {
      return null;
    }

    return user;
  }

  async getUserByFirstName(firstName: string) {
    // const user = await this.userRepository.findOne({ where: { username } });

    // if (!user) {
    //   return null;
    // }

    // return {
    //   email: user.email,
    //   firstName: user.firstName,
    // }
  }
  
  async DeleteUser(email: string) {
    const user = await this.getUserByEmailPrivate(email);
    
    if (!user) {
      return null;
    }

    return await this.userRepository.delete(user.id);
  }

  // user.service.ts
  async updateAvatar(email: string, file: Express.Multer.File) {
      // 1. Logica di upload (es. carichi su Supabase e ottieni l'URL)
      const publicUrl = `https://tuo-bucket.supabase.co/storage/v1/object/public/avatars/${file.originalname}`;

      // 2. Aggiorna il database usando TypeORM
      await this.userRepository.update(
          { email: email }, 
          { avatarUrl: publicUrl }
      );

      return { url: publicUrl };
  }
}