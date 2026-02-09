export interface TranslatorAdapter {
  translateText(text: string, targetLang: string): Promise<string>;
}
