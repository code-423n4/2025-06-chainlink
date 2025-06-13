const parse = require('lcov-parse');
const ignore = require('./coverage.ignore.json');

const COVERAGE_PERCENTAGE = 90.0; // 90% coverage

parse('./lcov.info', function (err, data) {
  data.forEach(({ file, branches, functions, lines }) => {
    if (file.startsWith('script') || file.startsWith('deploy')) return;

    const contract = file.slice(4, file.length - 4);

    if (ignore.libraries.includes(contract.slice(10, contract.length))) return;

    if (ignore[contract] && ignore[contract].branches) {
      branches.details = filterBranchDetails(contract, branches.details);
      branches.found = branches.details.length;
    }
    console.log(`Analyzing coverage for ${file}`);
    analyze(file, 'Branch', branches.hit, branches.found, branches.details);
    analyze(
      file,
      'Function',
      functions.hit,
      functions.found,
      functions.details
    );
    analyze(file, 'Line', lines.hit, lines.found, lines.details);
    console.log(`Coverage for ${file} is at 100%!`);
  });
});

const filterBranchDetails = (contract, details) => {
  ignore[contract].branches.forEach((ignoredHit) => {
    details = details.filter(({ line, block, branch, taken }) => {
      return !(
        line === ignoredHit.line &&
        block === ignoredHit.block &&
        branch === ignoredHit.branch &&
        taken === 0
      );
    });
  });

  return details;
};

const analyze = (file, section, numHits, numFound, details) => {
  if (numHits < numFound) {
    console.log(details);
    const percentage = (COVERAGE_PERCENTAGE * numHits) / numFound;
    throw new Error(`${section} coverage for ${file} is at ${percentage}%`);
  }
};
