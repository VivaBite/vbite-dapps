#!/usr/bin/env tsx

import { entropyToMnemonic } from 'bip39';
import { Buffer } from 'buffer';
import { HDNodeWallet } from 'ethers';

function fromPrivateKey(hexKey: string): void {
  const privKey = hexKey.startsWith('0x') ? hexKey.slice(2) : hexKey;

  if (privKey.length !== 64) {
    console.error('❌ Invalid private key length. Expected 64 hex characters.');
    process.exit(1);
  }

  const buffer = Buffer.from(privKey, 'hex');
  const entropy = Uint8Array.prototype.slice.call(buffer, 0, 16);
  const mnemonic = entropyToMnemonic(Buffer.from(entropy));
  const derived = HDNodeWallet.fromPhrase(mnemonic);

  console.log(
    '⚠️ Обратите внимание: восстановить оригинальный приватный ключ из мнемоники невозможно.'
  );
  console.log('🔑 Введённый приватный ключ: 0x' + privKey);
  console.log('📝 Сгенерированная мнемоника: ', mnemonic);
  console.log('🔐 Приватный ключ из мнемоники: ', derived.privateKey);
  console.log('📬 Адрес кошелька: ', derived.address);
}

const [, , keyArg] = process.argv;

if (!keyArg) {
  console.error(
    '⚠️ Укажите приватный ключ как аргумент:\n\n  pnpm tsx gen-mnemonic.ts <PRIVATE_KEY>'
  );
  process.exit(1);
}

fromPrivateKey(keyArg);
