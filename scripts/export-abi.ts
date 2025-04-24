#!/usr/bin/env tsx

import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CONTRACTS_DIR = path.resolve(__dirname, '../contracts');
const OUT_DIR = path.resolve(__dirname, '../out');
const DEST_DIR = path.resolve(__dirname, '../abi');

async function run() {
  await fs.ensureDir(DEST_DIR);

  const files = await fs.readdir(CONTRACTS_DIR);
  const solFiles = files.filter((file) => file.endsWith('.sol'));

  for (const file of solFiles) {
    const filePath = path.join(OUT_DIR, file);
    if (!(await fs.pathExists(filePath))) continue;

    const jsons = await fs.readdir(filePath);

    for (const json of jsons) {
      if (!json.endsWith('.json')) continue;

      const name = json.replace('.json', '');
      const contractJson = await fs.readJson(path.join(filePath, json));

      const abi = contractJson.abi;
      const bytecode = contractJson.bytecode?.object ?? contractJson.bytecode;

      if (!abi || !bytecode) {
        console.warn(`⚠ Пропущен: ${file}/${json} — отсутствует abi или bytecode`);
        continue;
      }

      const baseName = path.join(DEST_DIR, name);
      await fs.writeJson(`${baseName}.abi.json`, abi, { spaces: 2 });
      await fs.writeJson(`${baseName}.bytecode.json`, bytecode, { spaces: 2 });

      console.log(`✔ Exported ${name}`);
    }
  }
}

run().catch((err) => {
  console.error('❌ Export failed:', err);
  process.exit(1);
});
