#!/bin/bash
# 問題データを再結合してGitHub Pagesを更新するスクリプト
# 使い方: ./update.sh

set -e
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$APP_DIR/data"

echo "=== 問題データを結合中 ==="
python3 << 'PYEOF'
import json, os

data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else '.', 'data') + '/'
out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else '.', 'questions.js')

# data_dirをスクリプトのあるディレクトリから取得
import sys
script_dir = os.path.dirname(os.path.abspath(sys.argv[0])) if sys.argv[0] != '' else '.'
data_dir = script_dir + '/data/'
out_path = script_dir + '/questions.js'

all_questions = []
seen = {}

files = sorted(os.listdir(data_dir))
for fname in files:
    if not fname.endswith('.json'):
        continue
    try:
        with open(data_dir + fname, encoding='utf-8') as f:
            data = json.load(f)
        if not isinstance(data, list):
            continue
        for q in data:
            if not isinstance(q, dict):
                continue
            if not q.get('questionText') or not q.get('questionNumber'):
                continue
            key = (q.get('chapter', ''), q.get('questionNumber', 0))
            if key in seen:
                all_questions[seen[key]] = q
            else:
                seen[key] = len(all_questions)
                all_questions.append(q)
    except Exception as e:
        print(f'Error in {fname}: {e}')

ch_order = ['CH1','CH2','CH3','CH4','CH5','CH6','CH7','CH8','CH9','CH10']
def sort_key(q):
    ch = q.get('chapter', 'ZZ')
    try:
        ci = ch_order.index(ch)
    except ValueError:
        ci = 99
    return (ci, q.get('questionNumber', 999))

all_questions.sort(key=sort_key)

from collections import Counter
ch_counts = Counter(q.get('chapter','?') for q in all_questions)
print(f'総問題数: {len(all_questions)}問')
for ch in ch_order:
    if ch in ch_counts:
        print(f'  {ch}: {ch_counts[ch]}問')

js_content = f'''// 社労士問題集 問題データ（自動抽出）
// 総問題数: {len(all_questions)}問
const QUESTIONS = {json.dumps(all_questions, ensure_ascii=False, indent=2)};
'''

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(js_content)

print(f'questions.js 更新完了: {len(js_content):,} bytes')
PYEOF

echo ""
echo "=== GitHub Pagesへプッシュ中 ==="
cd "$APP_DIR"
git add questions.js
git commit -m "問題データ更新 ($(date '+%Y-%m-%d'))" || echo "変更なし"
git push origin main

echo ""
echo "✅ 更新完了！"
echo "🌐 URL: https://yuya42.github.io/sharoushi-quiz/"
