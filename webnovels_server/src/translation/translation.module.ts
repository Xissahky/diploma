import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { TranslationService } from './translation.service';
import { TranslationController } from './translation.controller';

@Module({
  imports: [PrismaModule],
  providers: [TranslationService],
  controllers: [TranslationController],
  exports: [TranslationService],
})
export class TranslationModule {}
