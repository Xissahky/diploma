import { Test, TestingModule } from '@nestjs/testing';
import { NovelsController } from './novels.controller';
import { NovelsService } from './novels.service';

describe('NovelsController', () => {
  let controller: NovelsController;

  const serviceMock = {
    searchNovels: jest.fn(),
    getAllTags: jest.fn(),
    recordView: jest.fn(),
    getPopular: jest.fn(),
    getTopRated: jest.fn(),
    getHomeSections: jest.fn(),
    getAll: jest.fn(),
    getOne: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    addChapter: jest.fn(),
    updateChapter: jest.fn(),
    deleteChapter: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [NovelsController],
      providers: [{ provide: NovelsService, useValue: serviceMock }],
    }).compile();

    controller = module.get(NovelsController);
  });

  // ---- search ----
  it('search should split tags, trim and pass mode', async () => {
    serviceMock.searchNovels.mockResolvedValue([{ id: 'n1' }]);

    const result = await controller.search('abc', ' tag1,tag2 , ,  ', 'all');

    expect(serviceMock.searchNovels).toHaveBeenCalledWith('abc', {
      tags: ['tag1', 'tag2'],
      mode: 'all',
    });
    expect(result).toEqual([{ id: 'n1' }]);
  });

  it('getAllTags should call service', async () => {
    serviceMock.getAllTags.mockResolvedValue(['a', 'b']);

    const result = await controller.getAllTags();

    expect(serviceMock.getAllTags).toHaveBeenCalled();
    expect(result).toEqual(['a', 'b']);
  });

  // ---- views ----
  it('recordViewAuthed should pass userId', async () => {
    serviceMock.recordView.mockResolvedValue({ ok: true });

    const result = await controller.recordViewAuthed('n1', { userId: 'u1' });

    expect(serviceMock.recordView).toHaveBeenCalledWith('n1', 'u1');
    expect(result).toEqual({ ok: true });
  });

  it('recordViewPublic should pass undefined userId', async () => {
    serviceMock.recordView.mockResolvedValue({ ok: true });

    const result = await controller.recordViewPublic('n1');

    expect(serviceMock.recordView).toHaveBeenCalledWith('n1', undefined);
    expect(result).toEqual({ ok: true });
  });

  // ---- popular/topRated defaults ----
  it('getPopular should use defaults when query params missing', async () => {
    serviceMock.getPopular.mockResolvedValue([]);

    await controller.getPopular(undefined, undefined);

    expect(serviceMock.getPopular).toHaveBeenCalledWith(14, 20);
  });

  it('getTopRated should use default limit=20', async () => {
    serviceMock.getTopRated.mockResolvedValue([]);

    await controller.getTopRated(undefined);

    expect(serviceMock.getTopRated).toHaveBeenCalledWith(20);
  });

  it('getSections should pass userId (optional chaining)', async () => {
    serviceMock.getHomeSections.mockResolvedValue({ popular: [] });

    const result = await controller.getSections({ userId: 'u1' });

    expect(serviceMock.getHomeSections).toHaveBeenCalledWith('u1');
    expect(result).toEqual({ popular: [] });
  });

  // ---- basic list/detail ----
  it('getAll should call service.getAll', async () => {
    serviceMock.getAll.mockResolvedValue([{ id: 'n1' }]);

    const result = await controller.getAll();

    expect(serviceMock.getAll).toHaveBeenCalled();
    expect(result).toEqual([{ id: 'n1' }]);
  });

  it('getOne should pass id and optional userId', async () => {
    serviceMock.getOne.mockResolvedValue({ id: 'n1' });

    const result = await controller.getOne('n1', { userId: 'u1' });

    expect(serviceMock.getOne).toHaveBeenCalledWith('n1', 'u1');
    expect(result).toEqual({ id: 'n1' });
  });

  // ---- CRUD ----
  it('create should map dto + current user to service.create', async () => {
    serviceMock.create.mockResolvedValue({ id: 'n1' });

    const dto = {
      title: 'T',
      description: 'D',
      coverUrl: '/x.png',
      tags: ['a'],
    } as any;

    const result = await controller.create(dto, { userId: 'u1' });

    expect(serviceMock.create).toHaveBeenCalledWith({
      title: 'T',
      description: 'D',
      coverUrl: '/x.png',
      authorId: 'u1',
      tags: ['a'],
    });
    expect(result).toEqual({ id: 'n1' });
  });

  it('update should forward id, userId and dto', async () => {
    serviceMock.update.mockResolvedValue({ id: 'n1' });

    const result = await controller.update('n1', { title: 'X' } as any, { userId: 'u1' });

    expect(serviceMock.update).toHaveBeenCalledWith('n1', 'u1', { title: 'X' });
    expect(result).toEqual({ id: 'n1' });
  });

  it('delete should forward id and userId', async () => {
    serviceMock.delete.mockResolvedValue({ id: 'n1' });

    const result = await controller.delete('n1', { userId: 'u1' });

    expect(serviceMock.delete).toHaveBeenCalledWith('n1', 'u1');
    expect(result).toEqual({ id: 'n1' });
  });

  // ---- chapters ----
  it('addChapter should forward novelId, userId and dto', async () => {
    serviceMock.addChapter.mockResolvedValue({ id: 'ch1' });

    const dto = { title: 'Ch', content: '...' } as any;
    const result = await controller.addChapter('n1', dto, { userId: 'u1' });

    expect(serviceMock.addChapter).toHaveBeenCalledWith('n1', 'u1', dto);
    expect(result).toEqual({ id: 'ch1' });
  });

  it('updateChapter should forward ids + userId + dto', async () => {
    serviceMock.updateChapter.mockResolvedValue({ id: 'ch1' });

    const dto = { title: 'New' } as any;
    const result = await controller.updateChapter('n1', 'ch1', dto, { userId: 'u1' });

    expect(serviceMock.updateChapter).toHaveBeenCalledWith('n1', 'ch1', 'u1', dto);
    expect(result).toEqual({ id: 'ch1' });
  });

  it('deleteChapter should forward ids + userId', async () => {
    serviceMock.deleteChapter.mockResolvedValue({ success: true });

    const result = await controller.deleteChapter('n1', 'ch1', { userId: 'u1' });

    expect(serviceMock.deleteChapter).toHaveBeenCalledWith('n1', 'ch1', 'u1');
    expect(result).toEqual({ success: true });
  });
});
