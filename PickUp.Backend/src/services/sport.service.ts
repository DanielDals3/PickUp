import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Sport } from '../core/entities/sport.entity';

@Injectable()
export class SportService {
    constructor(
        @InjectRepository(Sport)
        private readonly sportRepository: Repository<Sport>,
    ) {}
    
    async list(): Promise<Sport[]> {
        return await this.sportRepository.find({
            order: { name: 'ASC' } // Opzionale: li restituisce in ordine alfabetico
        });
    }
}