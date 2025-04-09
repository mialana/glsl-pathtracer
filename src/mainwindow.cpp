#include "mainwindow.h"
#include <ui_mainwindow.h>
#include "cameracontrolshelp.h"

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->mygl->setFocus();
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::slot_actionQuit_triggered()
{
    QApplication::exit();
}

void MainWindow::slot_actionCamera_Controls_triggered()
{
    CameraControlsHelp* c = new CameraControlsHelp();
    c->show();
}

void MainWindow::slot_actionLoad_Environment_Map_Ctrl_O_triggered()
{
    ui->mygl->loadEnvMap();
}

void MainWindow::slot_actionLoad_JSON_Scene_triggered()
{
    ui->mygl->loadJSON();
}
