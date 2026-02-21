import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Abilita CORS per permettere a Flutter di comunicare con il server
  app.enableCors();

  // await app.listen(process.env.PORT ?? 3000);
  await app.listen(8080, '0.0.0.0');
}
bootstrap();
