# Changelog

## [2.0.1] - 2024-09-07
- install packages from pinned versions
- docker complies once more
- previous version was not starting
- installed chaste from github master branch

## [2.0.0] - 2023-06-21
- updated to run via dynamic-sidecar
- Base image now uses the same as jupyterlab-math

## [1.0.1] - 2021-11-04
### Changed
- Added symbolic link between Chaste output path (~/chaste/testoutput) and working directory (~/work/testoutput))
## [1.0.0] - 2021-10-04
### Added
- Jupyter C++ kernel with Chaste (https://github.com/Chaste/chaste-docker) installed for Virtual Stomach team
- Basic Python kernel installed as well,  just in case 
- Symbolic link created between Chaste projects path (~/chaste/src/projects) and working directory (~/work/projects)

---
All notable changes to this service will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and the release numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


<!-- Add links here -->

<!-- HOW TO WRITE  THIS CHANGELOG

- Guiding Principles
  - Changelogs are for humans, not machines.
  - There should be an entry for every single version.
  - The same types of changes should be grouped.
  - Versions and sections should be linkable.
  - The latest version comes first.
  - The release date of each version is displayed.
  - Mention whether you follow Semantic Versioning.
  -
- Types of changes
  - Added for new features.
  - Changed for changes in existing functionality.
  - Deprecated for soon-to-be removed features.
  - Removed for now removed features.
  - Fixed for any bug fixes.
  - Security in case of vulnerabilities.

SEE https://keepachangelog.com/en/1.0.0/
-->
