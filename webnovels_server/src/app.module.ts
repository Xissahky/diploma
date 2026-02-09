import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { NovelsModule } from './novels/novels.module';
import { CommentsModule } from './comments/comments.module';
import { LibraryModule } from './library/library.module';
import { NotificationsModule } from './notifications/notifications.module'; 
import { RatingsModule } from './ratings/ratings.module';
import { TranslationModule } from './translation/translation.module';

import { UploadsController } from './uploads/uploads.controller';
import { ReportsModule } from './reports/report.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    UsersModule,
    NovelsModule,
    CommentsModule,
    LibraryModule,
    NotificationsModule,
    RatingsModule,
    TranslationModule,
    ReportsModule,
  ],
  controllers: [AppController, UploadsController],
  providers: [AppService],
})
export class AppModule {}
