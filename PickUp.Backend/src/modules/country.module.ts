import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Country } from '../core/entities/country.entity';
import { CountryController } from '../controller/country.controller';
import { CountryService } from '../services/country.service';

@Module({
  imports: [TypeOrmModule.forFeature([Country])], // Importante per usare Repository<Country>
  providers: [CountryService],
  controllers: [CountryController],
})
export class CountryModule {}