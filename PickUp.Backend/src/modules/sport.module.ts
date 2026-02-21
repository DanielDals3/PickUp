import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Sport } from '../core/entities/sport.entity';
import { SportController } from '../controller/sport.controller';
import { SportService } from 'src/services/sport.service';

@Module({
  imports: [TypeOrmModule.forFeature([Sport])], // Importante per usare Repository<Sport>
  providers: [SportService],
  controllers: [SportController],
})
export class SportModule {}