using System;
using System.IO;
using System.Reflection;
using CellTracking_Lib;
using MathWorks.MATLAB.NET.Arrays;

namespace CellTracking_App
{
    class Program
    {
        static void Main(string[] args)
        {
            // Matlab program object pointer
            CTType obj = null;

            // Result MWArray
            MWArray[] result = null;

            // Input variables
            string videoPath;
            string videoName;
            int maxSize;
            int minSize;
            int areaBool;
            int eccentricityBool;
            int orientationBool;

            // Read inputfile into variables
            string path = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), @"tempPort.txt");
            using (StreamReader sr = File.OpenText(path))
            {
                videoPath = sr.ReadLine();
                videoName = sr.ReadLine();
                maxSize = Int32.Parse(sr.ReadLine());
                minSize = Int32.Parse(sr.ReadLine());
                areaBool = Int32.Parse(sr.ReadLine());
                eccentricityBool = Int32.Parse(sr.ReadLine());
                orientationBool = Int32.Parse(sr.ReadLine());
            }

            // Run Matlab program
            // Because class instantiation and method invocation make their exceptions at run time,
            // you should enclose your code in a try-catch block to handle errors.
            try
            {
                // Instantiate your component class.
                obj = new CTType();

                // Invoke your component.
                result = obj.CellTracking_GUI(9, videoPath, videoName, maxSize, minSize, areaBool, eccentricityBool, orientationBool);

                // Write results to the output file
                using (StreamWriter writer = new StreamWriter(path))
                {
                    foreach (MWArray item in result)
                    {
                        writer.WriteLine(item);
                    }
                }
            }
            catch
            {
                throw;
            }
        }
    }
}