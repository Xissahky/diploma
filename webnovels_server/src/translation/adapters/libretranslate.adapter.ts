import axios from 'axios';
import { TranslatorAdapter } from './translator.adapter';

export class LibreTranslateAdapter implements TranslatorAdapter {
  constructor(private url: string) {}

  async translateText(text: string, targetLang: string): Promise<string> {
    const res = await axios.post(this.url, {
      q: text,
      source: 'auto',
      target: targetLang,
      format: 'text',
    }, { timeout: 30000 });
    return res.data?.translatedText ?? res.data?.translation ?? '';
  }
}
