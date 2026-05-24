import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const config = new DocumentBuilder()
    .setTitle('Video App API')
    .setDescription('Short-video application API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  app.enableCors();

  await app.listen(process.env.PORT ?? 3000);
  const port = process.env.PORT ?? 3000;
  console.log(`App running at http://localhost:${port}`);
  console.log(`Swagger docs at http://localhost:${port}/api`);
  console.log(`MinIO endpoint: ${process.env.MINIO_ENDPOINT ?? 'localhost'}:${process.env.MINIO_PORT ?? 9000}`);
  console.log(`Backend boot at ${new Date().toISOString()}`);
}
bootstrap();
