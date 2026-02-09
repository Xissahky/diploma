import { Test, TestingModule } from '@nestjs/testing';
import { CommentsController } from './comments.controller';
import { CommentsService } from './comments.service';

describe('CommentsController', () => {
  let controller: CommentsController;

  const commentsServiceMock = {
    getForNovel: jest.fn(),
    getForChapter: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CommentsController],
      providers: [
        { provide: CommentsService, useValue: commentsServiceMock },
      ],
    }).compile();

    controller = module.get(CommentsController);
  });

  it('getForNovel should call service.getForNovel', async () => {
    commentsServiceMock.getForNovel.mockResolvedValue([{ id: 'c1' }]);

    const result = await controller.getForNovel('n1');

    expect(commentsServiceMock.getForNovel).toHaveBeenCalledWith('n1');
    expect(result).toEqual([{ id: 'c1' }]);
  });

  it('getForChapter should call service.getForChapter', async () => {
    commentsServiceMock.getForChapter.mockResolvedValue([{ id: 'c2' }]);

    const result = await controller.getForChapter('ch1');

    expect(commentsServiceMock.getForChapter).toHaveBeenCalledWith('ch1');
    expect(result).toEqual([{ id: 'c2' }]);
  });

  it('create should map body + current user to service.create params', async () => {
    commentsServiceMock.create.mockResolvedValue({ id: 'c3' });

    const body = {
      content: 'Hello',
      novelId: 'n1',
      parentId: 'p1',
    };

    const user = { userId: 'u1' };

    const result = await controller.create(body as any, user as any);

    expect(commentsServiceMock.create).toHaveBeenCalledWith({
      authorId: 'u1',
      content: 'Hello',
      novelId: 'n1',
      chapterId: undefined,
      parentId: 'p1',
    });

    expect(result).toEqual({ id: 'c3' });
  });

  it('delete should call service.delete with id and userId', async () => {
    commentsServiceMock.delete.mockResolvedValue({ success: true });

    const result = await controller.delete('c1', { userId: 'u1' } as any);

    expect(commentsServiceMock.delete).toHaveBeenCalledWith('c1', 'u1');
    expect(result).toEqual({ success: true });
  });
});
