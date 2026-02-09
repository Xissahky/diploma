import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ReportStatus } from '@prisma/client';

export class UpdateReportAdminDto {
  @IsOptional()
  @IsEnum(ReportStatus)
  status?: ReportStatus; 

  @IsOptional()
  @IsString()
  action?: 'none' | 'delete_content' | 'ban_user';

  @IsOptional()
  @IsString()
  adminNote?: string;
}
