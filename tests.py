#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: ft=python fileencoding=utf-8 sts=4 sw=4 et:
# Copyright (C) 2022 J. Nathanael Philipp (jnphilipp) <nathanael@philipp.land>
"""Converter for different types of geo coordinates.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import os
import unittest

from csv import DictWriter
from subprocess import Popen, PIPE
from tempfile import TemporaryDirectory


class CoordconTests(unittest.TestCase):
    def test_as_arg(self):
        lat_long = (["51", "10"], ["51.000000", "10.000000"])
        utm = ["570168.862", "5650300.787", "32", "U"]

        p = Popen(
            [
                "./coordcon",
            ]
            + lat_long[0],
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate()[0]
        self.assertEqual(utm, output.split())

        p = Popen(
            [
                "./coordcon",
            ]
            + utm,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate()[0]
        self.assertEqual(lat_long[1], output.split())

        p = Popen(
            [
                "./coordcon",
            ]
            + utm[:2]
            + ["".join(utm[2:])],
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate()[0]
        self.assertEqual(lat_long[1], output.split())

    def test_as_input(self):
        lat_long = "51.000000 10.000000"
        utm = "570168.862 5650300.787 32 U"

        p = Popen(
            [
                "./coordcon",
            ],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate(input=lat_long)[0]
        self.assertEqual(utm, output.strip())

        p = Popen(
            [
                "./coordcon",
            ],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate(input=utm)[0]
        self.assertEqual(lat_long, output.strip())

        p = Popen(
            [
                "./coordcon",
            ],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate(input=utm[:-2] + utm[-1])[0]
        self.assertEqual(lat_long, output.strip())

        lat_long = """-11.350797 155.312500
0.000000 -30.000000
82.332000 -46.615000
-49.312813 69.109497
"""
        utm = """752386.614 8744229.492 56 L
166021.443 0.000 26 N
475944.783 9142225.593 23 X
507958.611 4537763.568 42 F
"""

        p = Popen(
            [
                "./coordcon",
            ],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate(input=lat_long)[0]
        self.assertEqual(utm, output)

        p = Popen(
            [
                "./coordcon",
            ],
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding="utf8",
        )
        output = p.communicate(input=utm)[0]
        self.assertEqual(lat_long, output)

    def test_as_csv_file(self):
        with TemporaryDirectory() as tmpdir:
            with open(os.path.join(tmpdir, "lat_long.csv"), "w", encoding="utf8") as f:
                writer = DictWriter(f, ["lat", "long"])
                writer.writeheader()
                writer.writerow({"lat": -11.350797, "long": 155.312500})
                writer.writerow({"lat": 0, "long": -30})
                writer.writerow({"lat": 82.332, "long": -46.615})
                writer.writerow({"lat": -49.312813, "long": 69.109497})

            utm = """"lat","long","Easting","Northing","Zone number","Zone letter"
"-11.350797","155.3125","752386.614","8744229.492","56","L"
"0","-30","166021.443","0.000","26","N"
"82.332","-46.615","475944.783","9142225.593","23","X"
"-49.312813","69.109497","507958.611","4537763.568","42","F"
"""
            p = Popen(
                ["./coordcon", os.path.join(tmpdir, "lat_long.csv")],
                stdout=PIPE,
                stderr=PIPE,
                encoding="utf8",
            )
            output = p.communicate()[0]
            self.assertEqual(utm, output)

            self.maxDiff = None
            with open(os.path.join(tmpdir, "utm.csv"), "w", encoding="utf8") as f:
                writer = DictWriter(
                    f, ["easting", "northing", "zone number", "zone letter"]
                )
                writer.writeheader()
                writer.writerow(
                    {
                        "easting": 752386.614,
                        "northing": 8744229.492,
                        "zone number": 56,
                        "zone letter": "L",
                    }
                )
                writer.writerow(
                    {
                        "easting": 166021.443,
                        "northing": 0.000,
                        "zone number": 26,
                        "zone letter": "N",
                    }
                )
                writer.writerow(
                    {
                        "easting": 475944.783,
                        "northing": 9142225.593,
                        "zone number": 23,
                        "zone letter": "X",
                    }
                )
                writer.writerow(
                    {
                        "easting": 507958.611,
                        "northing": 4537763.568,
                        "zone number": 42,
                        "zone letter": "F",
                    }
                )

            utm = """"easting","northing","zone number","zone letter","Longitude","Latitude"
"752386.614","8744229.492","56","L","155.312500","-11.350797"
"166021.443","0.0","26","N","-30.000000","0.000000"
"475944.783","9142225.593","23","X","-46.615000","82.332000"
"507958.611","4537763.568","42","F","69.109497","-49.312813"
"""
            p = Popen(
                ["./coordcon", os.path.join(tmpdir, "utm.csv")],
                stdout=PIPE,
                stderr=PIPE,
                encoding="utf8",
            )
            output = p.communicate()[0]
            self.assertEqual(utm, output)

            with open(os.path.join(tmpdir, "utm.csv"), "w", encoding="utf8") as f:
                writer = DictWriter(f, ["easting", "northing", "zone"])
                writer.writeheader()
                writer.writerow(
                    {"easting": 752386.614, "northing": 8744229.492, "zone": "56L"}
                )
                writer.writerow(
                    {"easting": 166021.443, "northing": 0.000, "zone": "26N"}
                )
                writer.writerow(
                    {"easting": 475944.783, "northing": 9142225.593, "zone": "23X"}
                )
                writer.writerow(
                    {"easting": 507958.611, "northing": 4537763.568, "zone": "42F"}
                )

            utm = """"easting","northing","zone","Longitude","Latitude"
"752386.614","8744229.492","56L","155.312500","-11.350797"
"166021.443","0.0","26N","-30.000000","0.000000"
"475944.783","9142225.593","23X","-46.615000","82.332000"
"507958.611","4537763.568","42F","69.109497","-49.312813"
"""
            p = Popen(
                ["./coordcon", os.path.join(tmpdir, "utm.csv")],
                stdout=PIPE,
                stderr=PIPE,
                encoding="utf8",
            )
            output = p.communicate()[0]
            self.assertEqual(utm, output)


if __name__ == "__main__":
    unittest.main()
