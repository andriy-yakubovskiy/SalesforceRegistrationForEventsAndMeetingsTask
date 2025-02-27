const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']

    , moduleFileExtensions: ['js', 'json', 'html'],
    moduleNameMapper: {
        '^@salesforce/(.*)$': '<rootDir>/force-app/main/default/lwc/$1/$1.js',
    },
    transform: {
        '^.+\\.js$': '<rootDir>/node_modules/@lwc/jest-transformer',
    },
    testEnvironment: 'jsdom'
};
