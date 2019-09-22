import setuptools


setuptools.setup(
    name="home",
    author='Cryolite',
    author_email='cryolite.indigo@gmail.com',
    url='https://github.com/Cryolite/home',
    version='0.0.1a1',

    python_requires='>= 3.6',
    install_requires=['python-daemon'],
    packages=setuptools.find_packages(),

    entry_points={
        'console_scripts': [
            'gnu_screen_helper = gnu_screen_helper.main:main',
        ],
    },
)
