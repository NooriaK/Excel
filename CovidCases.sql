-- Select Data that we are using
SELECT Location, date, total_cases, total_deaths, population
from CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likilihood of 
Select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
From CovidDeaths
WHERE location  like '%states%'
ORDER BY 1, 2

--Looking at total Cases vs Population
-- Shows what percentage of population got Covid
-- to ingore null from the Alias field
SELECT * FROM
(SELECT location AS Location, date as Date, population as Population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population),0))* 100 as PCTpopulationInfected
FROM CovidDeaths) as c
WHERE location like '%states%' and c.CasesPCT is not null
ORDER BY 1,2

-----------------------------------------------
SELECT location, date, population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population),0))* 100 as PCTpopulationInfected
FROM CovidDeaths
--WHERE location like '%states%' 

ORDER BY 1,2
-- Actual query if the data type was not varchar
SELECT location, population, MAX(total_cases) as HighInfectionCount, MAX(total_cases/population))*100 as PCTpopulationInfected from CovidDeaths
GROUP BY location, population
ORDER BY PCTpopulationInfected desc


--Looking at countries with the Highest Infection Rate compared to population, the field total_case was varchar therefore cast is used

select location, population, MAX(CAST(total_cases as float)) as HighestInfectedCount,
MAX(((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population),0))))* 100 as PCTpopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PCTpopulationInfected desc

-- Showing countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Let's break things down by continent -- To remove the blank cell use the > '' sign
SELECT distinct continent, MAX(CAST(Total_deaths as float)) AS TotalDeathCount FROM CovidDeaths
WHERE continent > ''
GROUP BY continent
ORDER BY TotalDeathCount DESC

--- Global numbers PCT Death & New Cases// NULLIF function to avoid dividing by zero error message.

SELECT SUM(CAST(new_cases AS float)) AS Total_cases, SUM(CAST(new_deaths as float)) as TotalDeaths,
SUM(((CONVERT(float, new_deaths) / NULLIF(CONVERT(float, new_cases),0))))* 100 as DeathPCT from CovidDeaths
WHERE continent > '' AND total_cases > CAST(0 as float)
--GROUP BY date
ORDER BY 1,2

-------looking at total population vs vaccination --------- Join table

SELECT dat.continent, dat.location,dat.date, dat.population,vac.new_vaccinations FROM CovidDeaths dat
JOIN CovidVaccination vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent is not null
ORDER BY 2,3

---- Partition
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dat.Location ORDER BY dat.location) AS RollingPeopleVaccinated
FROM CovidDeaths dat
JOIN CovidVaccination vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent IS NOT NULL AND vac.new_vaccinations> ''
ORDER BY 2,3

-- USE CTE --The conversion of the varchar value '4639847425' overflowed an int column.


with popvsVac 
(Continet,location,date,population,new_Vaccinations,RollingPeopleVaccinated)
AS
(
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dat.Location ORDER BY dat.location, dat.date) AS RollingPeopleVaccinated
FROM CovidDeaths dat
JOIN CovidVaccination vac
	ON dat.location = vac.location
	AND dat.date = vac.date
WHERE dat.continent = 'Europe' AND new_vaccinations >''
--ORDER BY 2,3
)
-- 
SELECT *,
CONCAT(CAST(CONVERT(float, RollingPeopleVaccinated) / NULLIF(CONVERT(float, Population),0) * 100 AS decimal(10,1)),'%')
AS PCTVactinatedPopulation FROM popvsVac

-- ---------------------------------------------------Showing PCT of population vaccinated using TEMP TABLE, a new temp table needs to be created
DROP Table IF EXISTS #PCTpopulationVaccinated
CREATE Table #PCTpopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population nvarchar(255),
New_vaccination nvarchar(255),
RollingPeopleVaccinated nvarchar(255)
)
INSERT INTO #PCTpopulationVaccinated
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location,dat.date) AS RollingPeopleVaccinated
FROM CovidDeaths dat
JOIN CovidVaccination vac
	ON dat.location = vac.location AND dat.date = vac.date
WHERE dat.continent = 'Europe' AND new_vaccinations >''

SELECT *, CONCAT(CAST(CONVERT(float, RollingPeopleVaccinated) / NULLIF(CONVERT(float, population),0) * 100 AS decimal (10,1)),'%')
AS PCTpopulationVaccinated FROM #PCTpopulationVaccinated

------------------- Create a View, the query can be used for visualization and connected to TABLEAU 

CREATE VIEW PCTpopulationVaccinated AS
SELECT dat.continent, dat.location, dat.date, dat.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dat.location ORDER BY dat.location,dat.date) AS RollingPeopleVaccinated
FROM CovidDeaths dat
JOIN CovidVaccination vac
	ON dat.location = vac.location AND dat.date = vac.date
WHERE dat.continent = 'Europe' AND new_vaccinations >''

--- Runt the view
SELECT * FROM PCTpopulationVaccinated
