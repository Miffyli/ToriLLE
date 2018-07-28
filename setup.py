import setuptools

# Just read the readme from what is used in github
with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="torille",
    version="0.9.2",
    author="Anssi 'Miffyli' Kanervisto",
    author_email="anssk@cs.uef.fi",
    description="Toribash as an agent learning environment",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Miffyli/ToriLLE",
    install_requires=[
        'numpy',
        'filelock'
    ],
    classifiers=(
        "Programming Language :: Python :: 3",
        "Development Status :: 5 - Production/Stable",
        "Operating System :: Unix",
        "Operating System :: Microsoft :: Windows",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)"
    ),
    packages=setuptools.find_packages(),
    include_package_data=True,
) 
