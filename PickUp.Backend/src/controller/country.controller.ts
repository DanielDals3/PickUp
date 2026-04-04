import { Controller, Get } from '@nestjs/common';
import { CountryService } from '../services/country.service';

@Controller('countries')
export class CountryController {
  constructor(private readonly countryService: CountryService) {}

  @Get('getCountries')  
  async getCountries() {
    return await this.countryService.findAll();
  }
}