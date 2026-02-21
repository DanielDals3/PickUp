import { Controller, Get, InternalServerErrorException } from '@nestjs/common';
import { SportService } from 'src/services/sport.service';

@Controller('sports')
export class SportController {
  constructor(private readonly sportService: SportService) {}

  @Get('list') // Rotta finale: GET /sports/list
  async getAllSports() {
    try {
      const sports = await this.sportService.list();
      if (!sports) return [];
      return sports;
    } catch (error) {
      // Logga l'errore lato server e invia un 500 al client
      console.error('Errore nel recupero sport:', error);
      throw new InternalServerErrorException('Impossibile recuperare la lista degli sport');
    }
  }
}