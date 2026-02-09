import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express'; 
import { join } from 'path'; 

async function bootstrap() {
  try {
    const app = await NestFactory.create<NestExpressApplication>(AppModule);

    app.enableCors();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

    app.useStaticAssets(join(__dirname, '..', 'uploads'), { prefix: '/uploads/' });

    const config = new DocumentBuilder()
      .setTitle('WebNovels API')
      .setDescription('REST API for the Web Novels mobile application')
      .setVersion('1.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api', app, document);

    await app.listen(3000);

    console.log('Server running at http://localhost:3000');
    console.log('Swagger available at http://localhost:3000/api');
    console.log('Static files served from /uploads/');
  } catch (err) {
    console.error(' Error starting server:', err);
  }
}
bootstrap();
