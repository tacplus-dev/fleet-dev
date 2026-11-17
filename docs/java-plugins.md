# Java services: Maven plugin dependencies

`dependencies.yaml` pins each Maven plugin's version (`lang.java.dependencies`), but Maven resolves every
plugin's own dependencies on its own classpath, apart from the project's and from each other's. A pin
cannot reach them: when a plugin release brings a vulnerable dependency, the service pom overrides it under
that plugin's `<dependencies>`. The exposure is the build, not the service's runtime.

## maven-shade-plugin: plexus-utils 3.6.1

maven-shade-plugin 3.6.1, the pin, asks for plexus-utils 3.5.1, and 3.6.2, the newest release, for 3.6.0.
Both have GHSA-6fmv-xxpf-w3cw (CVE-2025-67030, HIGH: a directory traversal in `Expand.extractFile`), fixed
in 3.6.1 (#17). Every Java service pom that declares maven-shade-plugin, in `<plugins>` or
`<pluginManagement>`, overrides it to 3.6.1, which stays on the 3.x line shade is built against:

```xml
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-shade-plugin</artifactId>
	<version>${shade-plugin.version}</version>
	<dependencies>
		<!-- GHSA-6fmv-xxpf-w3cw: shade 3.6.1 asks for plexus-utils 3.5.1 (fleet-dev docs/java-plugins.md) -->
		<dependency>
			<groupId>org.codehaus.plexus</groupId>
			<artifactId>plexus-utils</artifactId>
			<version>3.6.1</version>
		</dependency>
	</dependencies>
	...
</plugin>
```

An override in the parent's `<pluginManagement>` reaches every module that uses the plugin, merged with
any `<dependencies>` a module declares for it (Maven 3.9.16). A pom that declares the plugin outside the
parent's management, or with no parent, needs its own.

To see what the plugin actually runs on, build with `mvn -X package` and read the
`Populating class realm plugin>org.apache.maven.plugins:maven-shade-plugin:<version>` block:
its `Included: org.codehaus.plexus:plexus-utils:jar:<version>` line must say 3.6.1.
(`mvn dependency:resolve-plugins` shows the plugin's own pom dependencies, without the override.)

Drop the override once a shade release asks for plexus-utils 3.6.1 or later, and dependencies.yaml pins it.

## maven-antrun-plugin: plexus-utils 4.0.3

maven-antrun-plugin 3.2.0, the pin and the newest release, asks for plexus-utils 4.0.2, under
GHSA-6fmv-xxpf-w3cw too (fixed in 4.0.3 on the 4.x line, #18). Every Java service pom that declares
maven-antrun-plugin overrides it to 4.0.3, which stays on the 4.x line antrun 3.2.0 is built against:

```xml
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-antrun-plugin</artifactId>
	<version>3.2.0</version>
	<dependencies>
		<!-- GHSA-6fmv-xxpf-w3cw: antrun 3.2.0 asks for plexus-utils 4.0.2 (fleet-dev docs/java-plugins.md) -->
		<dependency>
			<groupId>org.codehaus.plexus</groupId>
			<artifactId>plexus-utils</artifactId>
			<version>4.0.3</version>
		</dependency>
	</dependencies>
	...
</plugin>
```

Bump antrun to 3.2.0 with the override, not before it: antrun 3.1.0, the former pin, is built against
plexus-utils 3.x and fails on 4.0.3 (`A required class was missing ... org/codehaus/plexus/util/xml/XmlStreamReader`,
which 4.x moved to plexus-xml), and its own 3.4.1 is affected. The same rules as shade's hold for where the
override goes, and its realm, `plugin>org.apache.maven.plugins:maven-antrun-plugin:3.2.0`, must include
plexus-utils 4.0.3. Drop it once an antrun release asks for 4.0.3 or later, and dependencies.yaml pins it.

## The default-lifecycle plugins: clean, resources, jar, install, deploy

Maven binds maven-clean-plugin, maven-resources-plugin, maven-jar-plugin, maven-install-plugin and
maven-deploy-plugin to the default lifecycle: they run in every build that reaches their phase, whether or
not a pom declares them, at the version the Maven running the build defaults to unless a pom pins it. Under
Maven 3.9.16 those defaults are clean 3.2.0 (commons-io 2.6: GHSA-78wr-2p64-hpwj, CVE-2024-47554, HIGH,
fixed in 2.14.0), resources 3.4.0 and jar 3.5.0 (plexus-utils 4.0.2; jar also aircompressor 0.27,
GHSA-vx9q-rhv9-3jvg) and install and deploy 3.1.4 (plexus-utils 4.0.1), all under GHSA-6fmv-xxpf-w3cw (#27).
dependencies.yaml pins clean 3.5.0, resources 3.5.0, jar 3.5.1, install 3.2.0 and deploy 3.2.0, and every
Java service pom that does not declare them adds them to `<pluginManagement>` at those versions. Two take
an override:

- maven-clean-plugin 3.5.0 asks for plexus-utils 4.0.2: override it to **4.0.3**, the 4.x line clean 3.5.0 is
  built against.
- maven-resources-plugin 3.5.0 asks for plexus-utils 3.6.0: override it to **3.6.1**, the 3.x line.

jar 3.5.1 (plexus-utils 4.0.3, plexus-archiver 4.12.0, commons-io 2.22.0, no aircompressor), install 3.2.0
and deploy 3.2.0 (plexus-utils 4.0.3) need none:

```xml
<pluginManagement>
	<plugins>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-clean-plugin</artifactId>
			<version>3.5.0</version>
			<dependencies>
				<!-- GHSA-6fmv-xxpf-w3cw: clean 3.5.0 asks for plexus-utils 4.0.2 (fleet-dev docs/java-plugins.md) -->
				<dependency>
					<groupId>org.codehaus.plexus</groupId>
					<artifactId>plexus-utils</artifactId>
					<version>4.0.3</version>
				</dependency>
			</dependencies>
		</plugin>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-resources-plugin</artifactId>
			<version>3.5.0</version>
			<dependencies>
				<!-- GHSA-6fmv-xxpf-w3cw: resources 3.5.0 asks for plexus-utils 3.6.0 (fleet-dev docs/java-plugins.md) -->
				<dependency>
					<groupId>org.codehaus.plexus</groupId>
					<artifactId>plexus-utils</artifactId>
					<version>3.6.1</version>
				</dependency>
			</dependencies>
		</plugin>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-jar-plugin</artifactId>
			<version>3.5.1</version>
		</plugin>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-install-plugin</artifactId>
			<version>3.2.0</version>
		</plugin>
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-deploy-plugin</artifactId>
			<version>3.2.0</version>
		</plugin>
	</plugins>
</pluginManagement>
```

The same rules as shade's hold for where the overrides go. Their realms
(`plugin>org.apache.maven.plugins:maven-clean-plugin:3.5.0` and so on) must include plexus-utils 4.0.3 (clean,
jar, install, deploy) and 3.6.1 (resources), and no commons-io below 2.14.0 or aircompressor below 2.0.3.
Drop an override once a release of that plugin asks for the fixed plexus-utils, and dependencies.yaml pins it.

The site plugin (3.12.1 under Maven 3.9.16) brings many more advisories (PROPOSALS.md); no gate or service
build runs `mvn site`, so it is not pinned here.

## maven-plugin-plugin (and maven-jar-plugin before 3.5.1): plexus-archiver 4.15.0

maven-jar-plugin 3.5.0 (Maven 3.9.16's default) and maven-plugin-plugin 3.15.1 ask for plexus-archiver
4.10.4 and 4.10.0, which load io.airlift:aircompressor 0.27: GHSA-vx9q-rhv9-3jvg (CVE-2025-67721, HIGH:
its Snappy and LZ4 decompressors can leak data from reused output buffers), fixed in 2.0.3. plexus-archiver
4.15.0, the newest release, no longer depends on aircompressor, so every Java service pom that runs
maven-plugin-plugin overrides plexus-archiver to 4.15.0, next to the plexus-utils 4.0.3 override it needs too
(it asks for plexus-utils 4.0.x below 4.0.3):

```xml
<plugin>
	<groupId>org.apache.maven.plugins</groupId>
	<artifactId>maven-plugin-plugin</artifactId>
	<version>3.15.1</version>
	<dependencies>
		<!-- GHSA-6fmv-xxpf-w3cw: plugin-plugin 3.15.1 asks for plexus-utils 4.0.x below 4.0.3 (fleet-dev docs/java-plugins.md) -->
		<dependency>
			<groupId>org.codehaus.plexus</groupId>
			<artifactId>plexus-utils</artifactId>
			<version>4.0.3</version>
		</dependency>
		<!-- GHSA-vx9q-rhv9-3jvg: plugin-plugin 3.15.1 brings plexus-archiver 4.10.0, which loads aircompressor 0.27
		     (fleet-dev docs/java-plugins.md) -->
		<dependency>
			<groupId>org.codehaus.plexus</groupId>
			<artifactId>plexus-archiver</artifactId>
			<version>4.15.0</version>
		</dependency>
	</dependencies>
</plugin>
```

maven-plugin-plugin's fixed line is pre-release (4.0.0-beta-2). With these overrides (kernel#37), the jar
and plugin-plugin realms included plexus-archiver 4.15.0, plexus-io 3.8.0 and no aircompressor, and kernel's
jars, `kernel.jar` among them, had the same entries with the same CRCs as without. jar 3.5.1, the pin, needs
neither override (#27): a pom that carries them for jar 3.5.0 drops them when it moves to 3.5.1. The same
rules as shade's hold for where the override goes. Drop it once a maven-plugin-plugin release asks for
plexus-archiver 4.15.0 or later, and dependencies.yaml pins it.

## exec-maven-plugin and build-helper-maven-plugin: the pins

No override: exec-maven-plugin 3.6.4 and build-helper-maven-plugin 3.6.2, the pins, run on plexus-utils
4.1.0 (and build-helper on commons-io 2.19.0). The former pins, exec 3.5.0 and build-helper 3.6.0, ran on
plexus-utils 4.0.2 and 4.0.1, and build-helper on commons-io 2.11.0, under GHSA-78wr-2p64-hpwj (CVE-2024-47554,
HIGH, fixed in 2.14.0) (#18). A service pom sets their versions (`exec-plugin.version`, say) to the pins.

## The checks

Both checks read every plugin class realm of their run from `mvn -X` (`checks/lib/realms.sh`), the
default-lifecycle plugins' included, and fail if any includes a plexus-utils under GHSA-6fmv-xxpf-w3cw (below
3.6.1, or 4.0.0 to 4.0.2), a commons-io below 2.14.0 or an aircompressor below 2.0.3.

`checks/shade.sh` (CI: `.github/workflows/shade-check.yml`) builds `checks/shade`, a jar shaded the way
the services shade theirs and with this override, at the shade, compiler and gson versions
`dependencies.yaml` pins, and with clean, resources, jar, install and deploy at their pins and overrides. It
runs `clean deploy`, to a scratch `file://` repository, so that the install and deploy realms are read too
(install puts `shade-check` 0-SNAPSHOT in the local repository). It fails unless the jar builds, runs, the
shade plugin's realm has plexus-utils 3.6.1 and nothing else, and each default-lifecycle plugin ran at its
pin. Run it after a change to those pins:

```
$ checks/shade.sh
shade check: maven-shade-plugin 3.6.1 on plexus-utils 3.6.1, compiler 3.16.0, gson 2.13.2: shaded jar builds and runs; clean 3.5.0, resources 3.5.0, jar 3.5.1, install 3.2.0, deploy 3.2.0: no affected plugin realm
```

It needs Maven 3.6.3 or later (maven-compiler-plugin 3.16.0) and a JDK 17 or later.

`checks/plugins.sh` (CI: `.github/workflows/plugins-check.yml`) runs `clean validate` in `checks/plugins`:
clean and a goal of each of antrun (with the override), exec and build-helper, at the versions
`dependencies.yaml` pins. It fails unless every one of them ran:

```
$ checks/plugins.sh
plugins check: maven-clean-plugin:3.5.0 on plexus-utils 4.0.3, maven-antrun-plugin:3.2.0 on plexus-utils 4.0.3, exec-maven-plugin:3.6.4 on plexus-utils 4.1.0, build-helper-maven-plugin:3.6.2 on plexus-utils 4.1.0 and commons-io 2.19.0
```
