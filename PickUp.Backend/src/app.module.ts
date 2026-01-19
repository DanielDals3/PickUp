import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './core/entities/user.entity';
import { UserModule } from './modules/user.module';

@Module({
  imports: [TypeOrmModule.forRoot({type: 'postgres',
      //TODO: configurare da un file .env
      // Inseire le credenziali del DB 
      host: '', 
      port: 1,
      username: '',
      password: '',
      database: '',
      entities: [User],
      // autoLoadEntities: true,
      // synchronize: true, // Da usare SOLO in sviluppo: crea le tabelle automaticamente in base al codice
    }),
    UserModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
