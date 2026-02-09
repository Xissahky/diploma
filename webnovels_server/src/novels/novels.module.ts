import { Module } from '@nestjs/common';
import { NovelsService } from './novels.service';
import { NovelsController } from './novels.controller';

@Module({
  providers: [NovelsService],
  controllers: [NovelsController]
})
export class NovelsModule {}
