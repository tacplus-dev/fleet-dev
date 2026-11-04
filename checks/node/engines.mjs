// The Node floor check (#20): tools.node admits only Node versions every package in the resolved trees
// runs on (each package's engines.node), and no Node line past its end of life (nodejs/Release
// schedule.json). Usage: node engines.mjs <semver dir> <tools.node> <schedule.json> <package-lock.json>...
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';

const [semverDir, tools, schedulePath, ...locks] = process.argv.slice(2);
const semver = createRequire(join(semverDir, 'noop.js'))('semver');
const range = new semver.Range(tools);
// tree <lock>: the tree a lockfile is of, the name of its directory (latest, floors).
const tree = (lock) => basename(dirname(lock));
let fail = false;

const today = new Date().toISOString().slice(0, 10);
for (const [line, { end }] of Object.entries(JSON.parse(readFileSync(schedulePath, 'utf8')))) {
	const major = Number(line.slice(1));
	if (!Number.isInteger(major) || major === 0 || end >= today) continue;
	if (semver.intersects(range, `>=${major}.0.0-0 <${major + 1}.0.0-0`, { includePrerelease: true })) {
		console.error(`node check: tools.node '${tools}' admits Node ${major}, end of life on ${end}`);
		fail = true;
	}
}

let highest = null;
for (const lock of locks) {
	const { packages } = JSON.parse(readFileSync(lock, 'utf8'));
	for (const [path, pkg] of Object.entries(packages)) {
		const engines = pkg.engines?.node;
		if (!path || !engines) continue;
		const name = `${path.replace(/^.*node_modules\//, '')} ${pkg.version}`;
		if (!semver.validRange(engines)) {
			console.error(`node check: ${name} has engines.node '${engines}', not a range`);
			fail = true;
			continue;
		}
		if (!semver.subset(range, engines)) {
			console.error(`node check: tools.node '${tools}' admits a Node ${name} does not run on (engines.node '${engines}', ${tree(lock)})`);
			fail = true;
		}
		const min = semver.minVersion(engines);
		if (!highest || semver.gt(min, highest.min)) highest = { min, name, engines };
	}
}
if (fail) process.exit(1);
console.log(`node check: tools.node '${tools}' is within every engines.node (highest floor: ${highest.name}, '${highest.engines}') and admits no end-of-life line`);
