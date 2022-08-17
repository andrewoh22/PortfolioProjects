SELECT *
FROM coviddeaths
WHERE continent IS NULL
ORDER BY 3,4;

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

-- Looking at total cases vs population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS DeathPercentage
FROM coviddeaths
-- WHERE location LIKE '%states%'
ORDER BY 1,2;

-- Looking at countries with highest infection rate compared to population
SELECT  location, 
		population, 
        MAX(total_cases) AS HighestInfectionCount, 
        MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing countries with highest death count per capita
SELECT  location, 
		MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Showing continents with the highest death count per population

SELECT  continent, 
		MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global numbers
SELECT  -- date, 
		SUM(new_cases) AS total_cases, 
        SUM(new_deaths) AS total_deaths,
        SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
-- GROUP BY date 
ORDER BY 1,2;

-- Looking at total population vs vaccinations
SELECT  dea.continent, 
		dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3;

-- Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
	SELECT  dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations,
			SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;

-- Temp table
UPDATE covidvaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations = '';

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
);
INSERT INTO PercentPopulationVaccinated
SELECT  dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			CAST(vac.new_vaccinations AS DECIMAL),
			SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
	-- WHERE dea.continent IS NOT NULL
;
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinated;

-- Creating view to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT  dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			CAST(vac.new_vaccinations AS DECIMAL),
			SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM coviddeaths AS dea
	JOIN covidvaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL;
    
SELECT *
FROM percentpopulationvaccinated;
