from setuptools import setup

with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="smtp-user-enum",
    version="0.1.0",
    description="SMTP user enumeration tool with clever timeout, retry and reconnect functionality.",
    license="MIT",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="cytopia",
    author_email="cytopia@everythingcli.org",
    url="https://github.com/cytopia/smtp-user-enum",
    install_requires=["argparse"],
    scripts=[
        "smtp-user-enum"
    ],
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 4 - Beta',

        # Indicate who your project is intended for
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Build Tools',

        # License
        "License :: OSI Approved :: MIT License",

        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
    ],
 )
