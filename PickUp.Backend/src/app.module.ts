import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './core/entities/user.entity';
import { UserModule } from './modules/user.module';
import { SportModule } from './modules/sport.module';
import { Sport } from './core/entities/sport.entity';
import { Country } from './core/entities/country.entity';
import { CountryModule } from './modules/country.module';

@Module({
  imports: 
    [
      TypeOrmModule.forRoot({type: 'postgres',
      //TODO: configurare da un file .env
      // Inseire le credenziali del DB 
      host: 'aws-1-eu-north-1.pooler.supabase.com',
      port: 5432,
      username: 'postgres.nfiegjsfzwzydwkfrwig',
      password: '7TOB2TxJezLgIeAs',
      database: 'postgres',
      entities: [User, Sport, Country],
      // autoLoadEntities: true,
      // synchronize: true, // Da usare SOLO in sviluppo: crea le tabelle automaticamente in base al codice
      ssl: {
        rejectUnauthorized: false, // Necessario per connettersi a Supabase/AWS da locale
      },
    }),
    UserModule,
    SportModule,
    CountryModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
