# Extract Chinese character bitmaps from hzk_mini12.h
import re

with open('hzk_mini12.h', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the array data
start = content.find('kernel_hzk12_mini[] = {') + len('kernel_hzk12_mini[] = {')
end = content.find('};', start)
data_str = content[start:end]

# Parse the hex values
values = [int(x.strip(), 16) for x in data_str.replace('\n', '').replace(' ', '').split(',') if x.strip()]

# Extract 登 (index 117) and 录 (index 118)
deng_start = 117 * 24
deng_data = values[deng_start:deng_start+24]
lu_start = 118 * 24
lu_data = values[lu_start:lu_start+24]

print('登 (index 117):')
print(', '.join(f'0x{v:02X}' for v in deng_data))
print()
print('录 (index 118):')
print(', '.join(f'0x{v:02X}' for v in lu_data))

# Print as bitmap
print()
print('登 bitmap:')
for i in range(12):
    b1 = deng_data[i*2]
    b2 = deng_data[i*2+1]
    row = ''
    for j in range(12):
        if j < 8:
            bit = (b1 >> (7-j)) & 1
        else:
            bit = (b2 >> (15-j)) & 1
        row += '#' if bit else '.'
    print(f'  {row}')

print()
print('录 bitmap:')
for i in range(12):
    b1 = lu_data[i*2]
    b2 = lu_data[i*2+1]
    row = ''
    for j in range(12):
        if j < 8:
            bit = (b1 >> (7-j)) & 1
        else:
            bit = (b2 >> (15-j)) & 1
        row += '#' if bit else '.'
    print(f'  {row}')