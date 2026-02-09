import OpenAI from 'openai';
import { TranslatorAdapter } from './translator.adapter';

export class OpenAIAdapter implements TranslatorAdapter {
  private client: OpenAI;
  private model: string;

  constructor(apiKey: string, model: string) {
    this.client = new OpenAI({ apiKey });
    this.model = model;
  }

  async translateText(text: string, targetLang: string): Promise<string> {
    const res = await this.client.chat.completions.create({
      model: this.model,
      messages: [
        { role: 'system', content: `You are a professional literary translator. Translate the user's text to ${targetLang}. Preserve meaning and style.` },
        { role: 'user', content: text },
      ],
      temperature: 0.2,
    });
    return res.choices?.[0]?.message?.content?.trim() ?? '';
    }
}
