import fs from 'fs';

/* extract ABI file from compiler output
```
   ts-node ./generateAPIFiles.ts
```
writes to ./abi folder
*/

const filenames = [
  'BUILDClaimSeason0',
  'SpaceAndTime'
];

filenames.forEach(filename => {
  const file = './out/' + filename + '.sol/' + filename + '.json';
  console.log(file);
  fs.readFile(file, 'utf-8', (err, data) => {
    if (err) {
      console.log('err', err);
      return;
    }

    const abi = JSON.parse(data).abi;
    fs.writeFile('./scripts/abi/' + filename + '.json', JSON.stringify(abi), err => {
      if (err) {
        console.log('err', err);
        return;
      }
    });
  });
});
