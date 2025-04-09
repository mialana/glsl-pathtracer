#include <mainwindow.h>

#include <mycpp/mystartup.h>

#include <QApplication>
#include <QSurfaceFormat>
#include <QDebug>

int main(int argc, char* argv[])
{
    QApplication a(argc, argv);

    startup::doSimpleSetup();

    MainWindow w;
    w.show();

    return a.exec();
}
