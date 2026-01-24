import { Controller, Post, Body, Get, Param, Query, Delete, UploadedFile, UseInterceptors, BadRequestException } from '@nestjs/common';
import { UserService } from '../services/user.service';
import { User } from '../core/models/user';
import { FileInterceptor } from '@nestjs/platform-express';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('register') // Rotta finale: POST /users/register
  async register(@Body() dto: User) {
    return this.userService.register(dto);
  }

  @Get('getByEmail') // Rotta finale: GET /users/get/pippo@qualcosa
  async getAllUsers(@Query('email') email: string) {
    return this.userService.getUserByEmail(email);
  }

  @Delete('delete') // Rotta finale: DELETE /users/delete/pippo@qualcosa
  async deleteUser(@Query('email') email: string) {
    return this.userService.DeleteUser(email);
  }

  @Post('upload-avatar')
  @UseInterceptors(FileInterceptor('file')) //Rotta finale: POST /users/upload-avatar
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('Nessun file caricato');
    }

    // Esempio di logica: il file buffer andrebbe inviato a Supabase o salvato in locale
    console.log('File ricevuto:', file.originalname);
    console.log('Dimensione:', file.size);

    // Qui chiamerai un metodo del service per l'upload reale
    // const url = await this.userService.uploadToStorage(file);
    
    return { 
      message: "File caricato con successo",
      url: `https://tuo-storage.com/avatars/${file.originalname}`, // URL fittizio
      size: file.size 
    };
  }
}