import { Controller, Post, Body, Get, Param, Query, Delete } from '@nestjs/common';
import { UserService } from '../services/user.service';
import { User } from '../core/models/user';

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
}