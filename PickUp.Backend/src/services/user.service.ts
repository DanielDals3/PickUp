import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../core/models/user';

export class UserService {
    constructor(
        @InjectRepository(User)
        private userRepository: Repository<User>,
    ) {}

    async register(dto: User) {
    // 1. Crea l'istanza dell'utente
    const newUser = this.userRepository.create(dto);
    
    // 2. Salva nel database
    // NOTA: In produzione qui dovrai criptare la password!
    return await this.userRepository.save(newUser);
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