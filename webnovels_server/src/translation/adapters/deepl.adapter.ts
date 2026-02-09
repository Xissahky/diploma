import axios from 'axios';
import { TranslatorAdapter } from './translator.adapter';

export class DeepLAdapter implements TranslatorAdapter {
  constructor(private apiKey: string, private apiUrl: string) {}

  async translateText(text: string, targetLang: string): Promise<string> {
    const params = new URLSearchParams();
    params.append('auth_key', this.apiKey);
    params.append('text', text);
    params.append('target_lang', targetLang.toUpperCase()); 

    const res = await axios.post(this.apiUrl, params, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      timeout: 30000,
    });

    const tr = res.data?.translations?.[0]?.text ?? '';
    return tr;
  }
}
