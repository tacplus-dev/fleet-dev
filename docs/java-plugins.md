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

## exec-maven-plugin and build-helper-maven-plugin: the pins

No override: exec-maven-plugin 3.6.4 and build-helper-maven-plugin 3.6.2, the pins, run on plexus-utils
4.1.0 (and build-helper on commons-io 2.19.0). The former pins, exec 3.5.0 and build-helper 3.6.0, ran on
plexus-utils 4.0.2 and 4.0.1, and build-helper on commons-io 2.11.0, under GHSA-78wr-2p64-hpwj (CVE-2024-47554,
HIGH, fixed in 2.14.0) (#18). A service pom sets their versions (`exec-plugin.version`, say) to the pins.

## The checks

`checks/shade.sh` (CI: `.github/workflows/shade-check.yml`) builds `checks/shade`, a jar shaded the way
the services shade theirs and with this override, at the shade, compiler and gson versions
`dependencies.yaml` pins. It fails unless the jar builds, runs, and the shade plugin's realm has
plexus-utils 3.6.1 and nothing else. Run it after a change to those pins:

```
$ checks/shade.sh
shade check: maven-shade-plugin 3.6.1 on plexus-utils 3.6.1, compiler 3.16.0, gson 2.13.2: shaded jar builds and runs
```

It needs Maven 3.6.3 or later (maven-compiler-plugin 3.16.0) and a JDK 17 or later.

`checks/plugins.sh` (CI: `.github/workflows/plugins-check.yml`) runs a goal of each of antrun (with the
override), exec and build-helper in `checks/plugins`, at the versions `dependencies.yaml` pins, and reads
each plugin's realm from `mvn -X`. It fails unless every plugin ran, and none of their realms includes a
plexus-utils under GHSA-6fmv-xxpf-w3cw (below 3.6.1, or 4.0.0 to 4.0.2) or a commons-io below 2.14.0:

```
$ checks/plugins.sh
plugins check: maven-antrun-plugin:3.2.0 on plexus-utils 4.0.3, exec-maven-plugin:3.6.4 on plexus-utils 4.1.0, build-helper-maven-plugin:3.6.2 on plexus-utils 4.1.0 and commons-io 2.19.0
```
